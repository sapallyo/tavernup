import 'package:tavernup_domain/tavernup_domain.dart';

class RemoteUserTaskRepository implements IUserTaskRepository {
  final IRealtimeTransport _transport;

  RemoteUserTaskRepository(this._transport);

  @override
  Future<void> create(UserTask task) async {
    // Server-internal — webhook handler creates user_tasks rows. The
    // Flutter client never calls this in practice; the server's RBA
    // wrapper rejects it for any UserPrincipal. Routed for completeness.
    throw UnsupportedError(
      'IUserTaskRepository.create is server-internal; clients cannot create '
      'user tasks directly. They are written by the WebhookHandler when '
      'Camunda fires a task-created event.',
    );
  }

  @override
  Future<void> delete(String taskId) async {
    await _transport.request('repo.userTask.delete', {'taskId': taskId});
  }

  @override
  Future<List<UserTask>> getForAssignee(String assigneeId) async {
    final result = (await _transport.request(
        'repo.userTask.getForAssignee',
        {'assigneeId': assigneeId}))['result'] as List;
    return result.map(_userTaskFromJson).toList();
  }

  @override
  Stream<List<UserTask>> watchForAssignee(String assigneeId) {
    return _transport
        .subscribeStream(
          repoName: 'userTask',
          method: 'watchForAssignee',
          args: {'assigneeId': assigneeId},
        )
        .map((event) => (event as List).map(_userTaskFromJson).toList());
  }

  UserTask _userTaskFromJson(dynamic raw) {
    final map = raw as Map<String, dynamic>;
    return UserTask(
      id: map['id'] as String,
      name: map['name'] as String,
      processInstanceId: map['processInstanceId'] as String,
      assignee: map['assignee'] as String,
      created: DateTime.parse(map['created'] as String),
      variables: (map['variables'] as Map<String, dynamic>).map((k, v) {
        final entry = v as Map<String, dynamic>;
        final type = VariableType.values.byName(entry['type'] as String);
        return MapEntry(k, Variable.fromTypeAndValue(type, entry['value']));
      }),
    );
  }
}
