import 'package:supabase/supabase.dart' hide User;
import 'package:tavernup_domain/tavernup_domain.dart';
import 'package:tavernup_repositories_supabase/tavernup_repositories_supabase.dart';
import 'package:test/test.dart';

import 'test_client.dart';

void main() {
  late SupabaseClient client;
  late SupabaseUserTaskRepository repository;

  setUp(() async {
    client = createTestClient();
    repository = SupabaseUserTaskRepository(client);
    await cleanTestData(client);
  });

  Future<String> setupAuthAndDomainUser(String name) async {
    final authId = await createTestAuthUser(client, testEmail(name));
    await client.from('users').insert({
      'id': authId,
      'nickname': name,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    return authId;
  }

  UserTask buildTask({
    required String assignee,
    String id = 'camunda-task-001',
    Map<String, Variable> variables = const {},
  }) {
    return UserTask(
      id: id,
      name: 'Test Task',
      processInstanceId: 'proc-001',
      assignee: assignee,
      variables: variables,
      created: DateTime.now().toUtc(),
    );
  }

  group('SupabaseUserTaskRepository', () {
    test('create and getForAssignee round-trip', () async {
      final assigneeId = await setupAuthAndDomainUser('assignee');
      final task = buildTask(assignee: assigneeId);

      await repository.create(task);
      final tasks = await repository.getForAssignee(assigneeId);

      expect(tasks, isNotEmpty);
      expect(tasks.first.id, equals(task.id));
      expect(tasks.first.assignee, equals(assigneeId));
    });

    test('Camunda task id (text) survives round-trip', () async {
      final assigneeId = await setupAuthAndDomainUser('assignee2');
      final camundaId = 'camunda-task-abc123-xyz';
      final task = buildTask(assignee: assigneeId, id: camundaId);

      await repository.create(task);
      final tasks = await repository.getForAssignee(assigneeId);

      expect(tasks.first.id, equals(camundaId));
    });

    test('variables round-trip for all VariableTypes', () async {
      final assigneeId = await setupAuthAndDomainUser('assignee3');
      final task = buildTask(
        assignee: assigneeId,
        id: 'camunda-task-vars',
        variables: {
          'strVar': Variable.fromTypeAndValue(VariableType.string, 'hello'),
          'intVar': Variable.fromTypeAndValue(VariableType.integer, 42),
          'boolVar': Variable.fromTypeAndValue(VariableType.boolean, true),
        },
      );

      await repository.create(task);
      final tasks = await repository.getForAssignee(assigneeId);
      final loaded = tasks.first;

      expect(loaded.variables['strVar']?.value, equals('hello'));
      expect(loaded.variables['intVar']?.value, equals(42));
      expect(loaded.variables['boolVar']?.value, equals(true));
    });

    test('delete removes task', () async {
      final assigneeId = await setupAuthAndDomainUser('assignee4');
      final task = buildTask(assignee: assigneeId);

      await repository.create(task);
      await repository.delete(task.id);

      final tasks = await repository.getForAssignee(assigneeId);
      expect(tasks, isEmpty);
    });

    test('getForAssignee returns empty list for user with no tasks', () async {
      final assigneeId = await setupAuthAndDomainUser('notasks');
      final result = await repository.getForAssignee(assigneeId);
      expect(result, isEmpty);
    });
  });
}
