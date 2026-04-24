import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tavernup_client/src/services/process_event_service.dart';
import 'package:tavernup_domain/tavernup_domain.dart';

UserTask _task(String id, String assignee) => UserTask(
      id: id,
      name: 'accept-invitation',
      processInstanceId: 'pi-1',
      variables: const {},
      assignee: assignee,
      created: DateTime(2026, 4, 24, 12),
    );

void main() {
  late MockUserTaskRepository repo;
  late MockRealtimeTransport transport;
  late ProcessEventService service;

  setUp(() async {
    repo = MockUserTaskRepository();
    transport = MockRealtimeTransport();
    await transport.connect();
    service = ProcessEventService(
      userTaskRepository: repo,
      transport: transport,
      userId: 'user-42',
    );
  });

  tearDown(() async {
    await repo.dispose();
    await transport.dispose();
  });

  test('pendingUserTasks emits only tasks assigned to the current user',
      () async {
    final emissions = <List<UserTask>>[];
    final sub = service.pendingUserTasks.listen(emissions.add);

    await repo.create(_task('t-1', 'user-42'));
    await repo.create(_task('t-2', 'someone-else'));
    await repo.create(_task('t-3', 'user-42'));

    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(emissions.last.map((t) => t.id), ['t-1', 't-3']);
  });

  test('completeUserTask sends complete-task request with taskId', () async {
    unawaited(service.completeUserTask(taskId: 'task-99'));
    await Future<void>.delayed(Duration.zero);

    expect(transport.sentRequests, hasLength(1));
    final sent = transport.sentRequests.single;
    expect(sent.type, 'complete-task');
    expect(sent.payload, {
      'taskId': 'task-99',
      'variables': <String, dynamic>{},
    });
  });

  test('completeUserTask serializes variables to raw values', () async {
    unawaited(service.completeUserTask(
      taskId: 'task-99',
      variables: {
        'nickname': Variable.string('alice'),
        'accepted': Variable.boolean(true),
      },
    ));
    await Future<void>.delayed(Duration.zero);

    expect(transport.sentRequests.single.payload, {
      'taskId': 'task-99',
      'variables': {
        'nickname': 'alice',
        'accepted': true,
      },
    });
  });

  test('completeUserTask returns after the server acknowledges', () async {
    final future = service.completeUserTask(taskId: 'task-99');
    await Future<void>.delayed(Duration.zero);

    var completed = false;
    future.then((_) => completed = true);
    expect(completed, isFalse,
        reason: 'should not complete before server responds');

    transport.respondTo('complete-task');
    await future;
    expect(completed, isTrue);
  });

  test('completeUserTask propagates server errors', () async {
    final future = service.completeUserTask(taskId: 'missing-task');
    await Future<void>.delayed(Duration.zero);

    transport.respondWithError(
      'complete-task',
      StateError('Task not found'),
    );

    await expectLater(
      future,
      throwsA(isA<StateError>()
          .having((e) => e.message, 'message', 'Task not found')),
    );
  });
}

