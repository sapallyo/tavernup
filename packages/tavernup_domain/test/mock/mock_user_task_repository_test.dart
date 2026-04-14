import 'package:test/test.dart';
import 'package:tavernup_domain/tavernup_domain.dart';

void main() {
  late MockUserTaskRepository repo;

  UserTask makeTask({
    required String id,
    required String assignee,
    String name = 'accept-invitation',
    String processInstanceId = 'proc-1',
  }) =>
      UserTask(
        id: id,
        name: name,
        processInstanceId: processInstanceId,
        variables: {},
        assignee: assignee,
        created: DateTime(2025, 1, 1),
      );

  setUp(() => repo = MockUserTaskRepository());
  tearDown(() => repo.dispose());

  group('create', () {
    test('adds a task', () async {
      await repo.create(makeTask(id: 't1', assignee: 'user-a'));
      final result = await repo.getForAssignee('user-a');
      expect(result, hasLength(1));
      expect(result.first.id, 't1');
    });

    test('throws on duplicate id', () async {
      await repo.create(makeTask(id: 't1', assignee: 'user-a'));
      expect(
        () => repo.create(makeTask(id: 't1', assignee: 'user-a')),
        throwsArgumentError,
      );
    });
  });

  group('delete', () {
    test('removes an existing task', () async {
      await repo.create(makeTask(id: 't1', assignee: 'user-a'));
      await repo.delete('t1');
      final result = await repo.getForAssignee('user-a');
      expect(result, isEmpty);
    });

    test('throws on unknown id', () async {
      expect(() => repo.delete('unknown'), throwsArgumentError);
    });
  });

  group('getForAssignee', () {
    test('returns only tasks for the given assignee', () async {
      await repo.create(makeTask(id: 't1', assignee: 'user-a'));
      await repo.create(makeTask(id: 't2', assignee: 'user-b'));
      final result = await repo.getForAssignee('user-a');
      expect(result.map((t) => t.id), ['t1']);
    });
  });

  group('watchForAssignee', () {
    test('emits updated list after create', () async {
      final future = repo.watchForAssignee('user-a').first;
      await repo.create(makeTask(id: 't1', assignee: 'user-a'));
      final result = await future;
      expect(result.map((t) => t.id), ['t1']);
    });

    test('emits updated list after delete', () async {
      await repo.create(makeTask(id: 't1', assignee: 'user-a'));
      final future = repo.watchForAssignee('user-a').first;
      await repo.delete('t1');
      final result = await future;
      expect(result, isEmpty);
    });

    test('does not emit tasks for other assignees', () async {
      final future = repo.watchForAssignee('user-a').first;
      await repo.create(makeTask(id: 't1', assignee: 'user-b'));
      final result = await future;
      expect(result, isEmpty);
    });
  });
}
