import 'package:supabase/supabase.dart' hide User;
import 'package:tavernup_domain/tavernup_domain.dart';
import 'package:tavernup_repositories_supabase/src/supabase_invitation_repository.dart';
import 'package:test/test.dart';

import 'test_client.dart';

void main() {
  late SupabaseClient client;
  late SupabaseInvitationRepository repository;

  setUp(() async {
    client = createTestClient();
    repository = SupabaseInvitationRepository(client);
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

  Future<GameGroup> setupGroup(String ownerId) async {
    final data = await client
        .from('game_groups')
        .insert({
          'name': 'Test Group',
          'created_by': ownerId,
          'ruleset': 'sr5',
        })
        .select()
        .single();
    final group = GameGroup.fromJson(data);
    await client.from('game_group_memberships').insert({
      'game_group_id': group.id,
      'user_id': ownerId,
      'role': GameGroupRole.admin.name,
    });
    return group;
  }

  Future<Invitation> createInvitationDirectly({
    required String gameGroupId,
    required String createdBy,
    required String invitedUserId,
    GameGroupRole role = GameGroupRole.player,
  }) async {
    final data = await client
        .from('invitations')
        .insert({
          'game_group_id': gameGroupId,
          'role': role.name,
          'created_by': createdBy,
          'invited_user_id': invitedUserId,
          'status': 'pending',
          'expires_at': DateTime.now()
              .add(const Duration(days: 7))
              .toUtc()
              .toIso8601String(),
        })
        .select()
        .single();
    return Invitation.fromJson(data);
  }

  group('SupabaseInvitationRepository', () {
    test('create via direct insert and getById round-trip', () async {
      final ownerId = await setupAuthAndDomainUser('owner');
      final invitedId = await setupAuthAndDomainUser('invited');
      final group = await setupGroup(ownerId);

      final invitation = await createInvitationDirectly(
        gameGroupId: group.id,
        createdBy: ownerId,
        invitedUserId: invitedId,
      );

      final loaded = await repository.getById(invitation.id);
      expect(loaded, isNotNull);
      expect(loaded!.id, equals(invitation.id));
      expect(loaded.invitedUserId, equals(invitedId));
    });

    test('getForUser returns pending invitations for user', () async {
      final ownerId = await setupAuthAndDomainUser('owner');
      final invitedId = await setupAuthAndDomainUser('invited');
      final group = await setupGroup(ownerId);

      await createInvitationDirectly(
        gameGroupId: group.id,
        createdBy: ownerId,
        invitedUserId: invitedId,
      );

      final invitations = await repository.getForUser(invitedId);
      expect(invitations, isNotEmpty);
      expect(invitations.first.invitedUserId, equals(invitedId));
    });

    test('getForUser returns empty list for user with no invitations',
        () async {
      final userId = await setupAuthAndDomainUser('noinvite');
      final result = await repository.getForUser(userId);
      expect(result, isEmpty);
    });

    test('getForGameGroup returns all invitations for group', () async {
      final ownerId = await setupAuthAndDomainUser('owner');
      final invited1 = await setupAuthAndDomainUser('invited1');
      final invited2 = await setupAuthAndDomainUser('invited2');
      final group = await setupGroup(ownerId);

      await createInvitationDirectly(
        gameGroupId: group.id,
        createdBy: ownerId,
        invitedUserId: invited1,
      );
      await createInvitationDirectly(
        gameGroupId: group.id,
        createdBy: ownerId,
        invitedUserId: invited2,
      );

      final invitations = await repository.getForGameGroup(group.id);
      expect(invitations.length, equals(2));
    });

    test('create with non-existent game group throws', () async {
      final ownerId = await setupAuthAndDomainUser('owner');
      final invitedId = await setupAuthAndDomainUser('invited');

      expect(
        () => createInvitationDirectly(
          gameGroupId: '00000000-0000-0000-0000-000000000099',
          createdBy: ownerId,
          invitedUserId: invitedId,
        ),
        throwsA(isA<PostgrestException>()),
      );
    });

    test('create with non-existent invited user throws', () async {
      final ownerId = await setupAuthAndDomainUser('owner');
      final group = await setupGroup(ownerId);

      expect(
        () => createInvitationDirectly(
          gameGroupId: group.id,
          createdBy: ownerId,
          invitedUserId: '00000000-0000-0000-0000-000000000099',
        ),
        throwsA(isA<PostgrestException>()),
      );
    });
  });
}
