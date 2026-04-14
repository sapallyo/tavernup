import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:tavernup_domain/tavernup_domain.dart';
import 'package:test/test.dart';

import 'package:tavernup_server/src/webhook/webhook_handler.dart';

void main() {
  late MockUserTaskRepository userTaskRepository;
  late List<void> externalTaskNotifications;
  late WebhookHandler handler;

  setUp(() {
    userTaskRepository = MockUserTaskRepository();
    externalTaskNotifications = [];
    handler = WebhookHandler(
      userTaskRepository: userTaskRepository,
      onExternalTaskCreated: () => externalTaskNotifications.add(null),
    );
  });

  tearDown(() => userTaskRepository.dispose());

  Request makeRequest(Map<String, dynamic> body) => Request(
        'POST',
        Uri.parse('http://localhost/webhook/task-created'),
        body: jsonEncode(body),
      );

  group('userTask', () {
    test('creates UserTask in repository', () async {
      final response = await handler.handleTaskCreated(makeRequest({
        'taskType': 'userTask',
        'taskId': 't-1',
        'taskName': 'accept-invitation',
        'processInstanceId': 'proc-1',
        'assignee': 'user-1',
        'variables': {'groupId': 'group-42'},
      }));

      expect(response.statusCode, 200);
      final tasks = await userTaskRepository.getForAssignee('user-1');
      expect(tasks, hasLength(1));
      expect(tasks.first.id, 't-1');
      expect(tasks.first.variables['groupId']?.value, 'group-42');
    });

    test('returns 400 for missing assignee', () async {
      final response = await handler.handleTaskCreated(makeRequest({
        'taskType': 'userTask',
        'taskId': 't-1',
        'taskName': 'accept-invitation',
        'processInstanceId': 'proc-1',
      }));
      expect(response.statusCode, 400);
    });
  });

  group('externalTask', () {
    test('triggers onExternalTaskCreated callback', () async {
      final response = await handler.handleTaskCreated(makeRequest({
        'taskType': 'externalTask',
        'taskId': 't-2',
        'taskName': 'entity-operation',
        'processInstanceId': 'proc-1',
      }));

      expect(response.statusCode, 200);
      expect(externalTaskNotifications, hasLength(1));
    });
  });

  group('validation', () {
    test('returns 400 for invalid JSON', () async {
      final request = Request(
        'POST',
        Uri.parse('http://localhost/webhook/task-created'),
        body: 'not json',
      );
      final response = await handler.handleTaskCreated(request);
      expect(response.statusCode, 400);
    });

    test('returns 400 for missing required fields', () async {
      final response = await handler.handleTaskCreated(makeRequest({
        'taskType': 'userTask',
      }));
      expect(response.statusCode, 400);
    });
  });
}
