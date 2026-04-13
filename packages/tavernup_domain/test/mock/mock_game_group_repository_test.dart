import 'package:test/test.dart';
import 'package:tavernup_domain/tavernup_domain.dart';

void main() {
  group('MockGameGroupRepository', () {
    late MockGameGroupRepository repo;

    final group1 = GameGroup(
      id: 'group-1',
      name: 'Shadowrun Runde',
      createdBy: 'user-1',
      createdAt: DateTime(2024, 1, 15),
    );

    final membership1 = GameGroupMembership(
      id: 'mem-1',
      gameGroupId: 'group-1',
      userId: 'user-1',
      role: GameGroupRole.gm,
      joinedAt: DateTime(2024, 1, 15),
    );

    final membership2 = GameGroupMembership(
      id: 'mem-2',
      gameGroupId: 'group-1',
      userId: 'user-2',
      role: GameGroupRole.player,
      joinedAt: DateTime(2024, 1, 15),
    );

    setUp(() {
      repo = MockGameGroupRepository();
      repo.seed([group1], memberships: [membership1, membership2]);
    });

    test('getAll returns groups for user', () async {
      final groups = await repo.getAll('user-1');
      expect(groups.length, 1);
      expect(groups.first.id, 'group-1');
    });

    test('getAll returns empty for user with no groups', () async {
      expect(await repo.getAll('user-3'), isEmpty);
    });

    test('getById returns correct group', () async {
      expect((await repo.getById('group-1'))?.name, 'Shadowrun Runde');
    });

    test('create adds new group', () async {
      final created = await repo.createGameGroup('DSA Runde', null, 'dsa4');
      expect(await repo.getById(created.id), isNotNull);
      expect(created.ruleset, 'dsa4');
    });

    test('getMembers returns all members', () async {
      final members = await repo.getMembers('group-1');
      expect(members.length, 2);
    });

    test('addMember adds membership', () async {
      await repo.addMember('group-1', 'user-3', GameGroupRole.player);
      final members = await repo.getMembers('group-1');
      expect(members.length, 3);
    });

    test('removeMember removes membership', () async {
      await repo.removeMember('group-1', 'user-2', GameGroupRole.player);
      final members = await repo.getMembers('group-1');
      expect(members.length, 1);
    });

    test('getRolesForUser returns correct roles', () async {
      final roles = await repo.getRolesForUser('group-1', 'user-1');
      expect(roles, contains(GameGroupRole.gm));
    });

    test('getRolesForUser returns empty for non-member', () async {
      expect(await repo.getRolesForUser('group-1', 'user-99'), isEmpty);
    });
  });
}
