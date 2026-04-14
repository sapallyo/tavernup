import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:tavernup_domain/tavernup_domain.dart';

/// Handles incoming webhook calls from the Camunda TaskListener.
///
/// Camunda fires a POST to `/webhook/task-created` whenever a new task
/// (UserTask or ExternalTask) is created. The handler inspects the task
/// type and either:
/// - writes a [UserTask] to [IUserTaskRepository] (UserTask), or
/// - notifies the worker loop to trigger fetchAndLock (ExternalTask).
class WebhookHandler {
  final IUserTaskRepository _userTaskRepository;
  final void Function() _onExternalTaskCreated;

  WebhookHandler({
    required IUserTaskRepository userTaskRepository,
    required void Function() onExternalTaskCreated,
  })  : _userTaskRepository = userTaskRepository,
        _onExternalTaskCreated = onExternalTaskCreated;

  Future<Response> handleTaskCreated(Request request) async {
    final body = await request.readAsString();
    final Map<String, dynamic> json;

    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return Response(400, body: 'Invalid JSON');
    }

    final taskType = json['taskType'] as String?;
    final taskId = json['taskId'] as String?;
    final taskName = json['taskName'] as String?;
    final processInstanceId = json['processInstanceId'] as String?;
    final assignee = json['assignee'] as String?;

    if (taskType == null ||
        taskId == null ||
        taskName == null ||
        processInstanceId == null) {
      return Response(400, body: 'Missing required fields');
    }

    if (taskType == 'userTask') {
      if (assignee == null) {
        return Response(400, body: 'Missing assignee for userTask');
      }
      final variables = _parseVariables(json['variables']);
      final task = UserTask(
        id: taskId,
        name: taskName,
        processInstanceId: processInstanceId,
        variables: variables,
        assignee: assignee,
        created: DateTime.now(),
      );
      await _userTaskRepository.create(task);
    } else if (taskType == 'externalTask') {
      _onExternalTaskCreated();
    }

    return Response(200, body: 'ok');
  }

  Map<String, Variable> _parseVariables(dynamic raw) {
    if (raw is! Map<String, dynamic>) return {};
    final result = <String, Variable>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is String)
        result[entry.key] = Variable.string(value);
      else if (value is int)
        result[entry.key] = Variable.integer(value);
      else if (value is double)
        result[entry.key] = Variable.double(value);
      else if (value is bool)
        result[entry.key] = Variable.boolean(value);
      else if (value is Map<String, dynamic>)
        result[entry.key] = Variable.json(value);
    }
    return result;
  }
}
