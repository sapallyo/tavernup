import 'package:test/test.dart';
import 'package:tavernup_domain/tavernup_domain.dart';

void main() {
  group('MockInvitationRepository', () {
    late MockInvitationRepository repo;

    setUp(() => repo = MockInvitationRepository());

    test('createInvitation stores and returns invitation', () async {
      final inv = await repo.createInvitation(
        'group-1',
        GameGroupRole.player,
        'user-2',
      );
      expect(inv.gameGroupId, 'group-1');
      expect(inv.status, InvitationStatus.pending);
      expect(await repo.getById(inv.id), isNotNull);
    });

    test('getForUser returns invitations for user', () async {
      await repo.createInvitation('group-1', GameGroupRole.player, 'user-2');
      await repo.createInvitation('group-1', GameGroupRole.player, 'user-3');
      expect((await repo.getForUser('user-2')).length, 1);
    });

    test('getForGameGroup returns all invitations for group', () async {
      await repo.createInvitation('group-1', GameGroupRole.player, 'user-2');
      await repo.createInvitation('group-1', GameGroupRole.gm, 'user-3');
      expect((await repo.getForGameGroup('group-1')).length, 2);
    });

    test('update changes status', () async {
      final inv = await repo.createInvitation(
        'group-1',
        GameGroupRole.player,
        'user-2',
      );
      await repo.update(inv.id, {'status': 'accepted'});
      final updated = await repo.getById(inv.id);
      expect(updated?.status, InvitationStatus.accepted);
    });

    test('delete removes invitation', () async {
      final inv = await repo.createInvitation(
        'group-1',
        GameGroupRole.player,
        'user-2',
      );
      await repo.delete(inv.id);
      expect(await repo.getById(inv.id), isNull);
    });
  });
}
