import 'package:supabase/supabase.dart' hide User, Session;
import 'package:tavernup_domain/tavernup_domain.dart';
import 'package:tavernup_repositories_supabase/tavernup_repositories_supabase.dart';
import 'package:test/test.dart';

import 'test_client.dart';

void main() {
  late SupabaseClient client;
  late SupabaseSessionRepository repository;

  setUp(() async {
    client = createTestClient();
    repository = SupabaseSessionRepository(client);
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

  Future<Session> createSessionDirectly(String createdBy) async {
    final data = await client
        .from('sessions')
        .insert({
          'created_by': createdBy,
          'instance_ids': [],
          'participants': [],
        })
        .select()
        .single();
    return Session.fromJson(data);
  }

  group('SupabaseSessionRepository', () {
    test('create and getById round-trip', () async {
      final userId = await setupAuthAndDomainUser('user');
      final session = await createSessionDirectly(userId);

      final loaded = await repository.getById(session.id);
      expect(loaded, isNotNull);
      expect(loaded!.id, equals(session.id));
    });

    test('getById returns null for unknown id', () async {
      final result =
          await repository.getById('00000000-0000-0000-0000-000000000099');
      expect(result, isNull);
    });

    test('getByIds returns correct sessions', () async {
      final userId = await setupAuthAndDomainUser('user');
      final s1 = await createSessionDirectly(userId);
      final s2 = await createSessionDirectly(userId);

      final loaded = await repository.getByIds([s1.id, s2.id]);
      expect(loaded.map((s) => s.id), containsAll([s1.id, s2.id]));
    });

    test('getByIds with empty list returns empty', () async {
      final result = await repository.getByIds([]);
      expect(result, isEmpty);
    });

    test('addInstance and removeInstance', () async {
      final userId = await setupAuthAndDomainUser('user');
      final session = await createSessionDirectly(userId);
      const instanceId = 'instance-001';

      await repository.addInstance(session.id, instanceId);
      final afterAdd = await repository.getById(session.id);
      expect(afterAdd!.instanceIds, contains(instanceId));

      await repository.removeInstance(session.id, instanceId);
      final afterRemove = await repository.getById(session.id);
      expect(afterRemove!.instanceIds, isNot(contains(instanceId)));
    });

    test('addParticipant and removeParticipant', () async {
      final userId = await setupAuthAndDomainUser('user');
      final session = await createSessionDirectly(userId);

      final participant = AdventureCharacter(
        id: 'ac-001',
        userId: userId,
        characterId: 'char-001',
        addedAt: DateTime.now().toUtc(),
      );

      await repository.addParticipant(session.id, participant);
      final afterAdd = await repository.getById(session.id);
      expect(afterAdd!.participants.map((p) => p.id), contains('ac-001'));

      await repository.removeParticipant(session.id, 'ac-001');
      final afterRemove = await repository.getById(session.id);
      expect(afterRemove!.participants.map((p) => p.id),
          isNot(contains('ac-001')));
    });

    test('delete removes session', () async {
      final userId = await setupAuthAndDomainUser('user');
      final session = await createSessionDirectly(userId);

      await repository.delete(session.id);
      final loaded = await repository.getById(session.id);
      expect(loaded, isNull);
    });
  });
}
