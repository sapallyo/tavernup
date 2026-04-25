import 'package:supabase/supabase.dart' hide User;
import 'package:tavernup_domain/tavernup_domain.dart';
import 'package:tavernup_repositories_supabase/src/supabase_game_group_repository.dart';
import 'package:test/test.dart';

import 'test_client.dart';

void main() {
  late SupabaseClient client;
  late SupabaseGameGroupRepository repository;

  setUp(() async {
    client = createTestClient();
    repository = SupabaseGameGroupRepository(client);
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

  group('SupabaseGameGroupRepository', () {
    test('createGameGroup and getById round-trip', () async {
      final ownerId = await setupAuthAndDomainUser('owner');
      final group = await _createGroupAs(client, ownerId, 'Test Group');

      final loaded = await repository.getById(group.id);
      expect(loaded, isNotNull);
      expect(loaded!.name, equals('Test Group'));
    });

    test('addMember and getMembers', () async {
      final ownerId = await setupAuthAndDomainUser('owner2');
      final memberId = await setupAuthAndDomainUser('member');

      final group = await _createGroupAs(client, ownerId, 'Group With Members');
      await repository.addMember(group.id, memberId, GameGroupRole.player);

      final members = await repository.getMembers(group.id);
      expect(members.map((m) => m.userId), contains(memberId));
    });

    test('removeMember removes existing member', () async {
      final ownerId = await setupAuthAndDomainUser('owner3');
      final memberId = await setupAuthAndDomainUser('toleave');

      final group = await _createGroupAs(client, ownerId, 'Group Leave');
      await repository.addMember(group.id, memberId, GameGroupRole.player);
      await repository.removeMember(group.id, memberId, GameGroupRole.player);

      final members = await repository.getMembers(group.id);
      expect(members.map((m) => m.userId), isNot(contains(memberId)));
    });

    test('removeMember on non-member does not throw', () async {
      final ownerId = await setupAuthAndDomainUser('owner4');
      final nonMemberId = await setupAuthAndDomainUser('nonmember');

      final group = await _createGroupAs(client, ownerId, 'Group NoRemove');

      expect(
        () => repository.removeMember(
            group.id, nonMemberId, GameGroupRole.player),
        returnsNormally,
      );
    });

    test('addMember twice throws', () async {
      final ownerId = await setupAuthAndDomainUser('owner5');
      final memberId = await setupAuthAndDomainUser('double');

      final group = await _createGroupAs(client, ownerId, 'Group Double');
      await repository.addMember(group.id, memberId, GameGroupRole.player);

      expect(
        () => repository.addMember(group.id, memberId, GameGroupRole.player),
        throwsA(isA<PostgrestException>()),
      );
    });

    test('getRolesForUser returns correct role', () async {
      final ownerId = await setupAuthAndDomainUser('owner6');
      final memberId = await setupAuthAndDomainUser('rolecheck');

      final group = await _createGroupAs(client, ownerId, 'Group Roles');
      await repository.addMember(group.id, memberId, GameGroupRole.player);

      final roles = await repository.getRolesForUser(group.id, memberId);
      expect(roles, contains(GameGroupRole.player));
    });

    test('getAll returns groups for member', () async {
      final ownerId = await setupAuthAndDomainUser('owner7');
      final group = await _createGroupAs(client, ownerId, 'Group GetAll');

      final groups = await repository.getAll(ownerId);
      expect(groups.map((g) => g.id), contains(group.id));
    });
  });
}

Future<GameGroup> _createGroupAs(
  SupabaseClient client,
  String userId,
  String name,
) async {
  final data = await client
      .from('game_groups')
      .insert({
        'name': name,
        'created_by': userId,
        'ruleset': 'sr5',
      })
      .select()
      .single();
  final group = GameGroup.fromJson(data);
  await client.from('game_group_memberships').insert({
    'game_group_id': group.id,
    'user_id': userId,
    'role': GameGroupRole.admin.name,
  });
  return group;
}
