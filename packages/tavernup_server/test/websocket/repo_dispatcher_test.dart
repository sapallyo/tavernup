import 'package:tavernup_domain/tavernup_domain.dart';
import 'package:test/test.dart';

import 'package:tavernup_server/src/rba/rba_repository_bundle.dart';
import 'package:tavernup_server/src/websocket/repo_dispatcher.dart';

({MockUserRepository user, MockGameGroupRepository gameGroup,
  MockInvitationRepository invitation, RbaRepositoryBundle bundle})
    _bundle() {
  final user = MockUserRepository();
  final gameGroup = MockGameGroupRepository();
  final invitation = MockInvitationRepository();
  return (
    user: user,
    gameGroup: gameGroup,
    invitation: invitation,
    bundle: RbaRepositoryBundle(
      user: user,
      character: MockCharacterRepository(),
      gameGroup: gameGroup,
      invitation: invitation,
      storyNode: MockStoryNodeRepository(),
      storyNodeInstance: MockStoryNodeInstanceRepository(),
      session: MockSessionRepository(),
      userTask: MockUserTaskRepository(),
    ),
  );
}

void main() {
  late RepoDispatcher dispatcher;

  setUp(() => dispatcher = RepoDispatcher());

  group('routing — read methods', () {
    test('user.findByNickname serialises the result via toJson', () async {
      final h = _bundle();
      h.user.seed([
        User(
          id: 'u-1',
          nickname: 'alice',
          createdAt: DateTime(2026, 4, 24).toUtc(),
        ),
      ]);

      final result = await dispatcher.dispatch(
        'repo.user.findByNickname',
        {'nickname': 'alice'},
        h.bundle,
      );

      expect(result, isA<Map<String, dynamic>>());
      expect((result as Map)['id'], 'u-1');
      expect(result['nickname'], 'alice');
    });

    test('user.findByNickname returns null for unknown nickname', () async {
      final h = _bundle();
      final result = await dispatcher.dispatch(
        'repo.user.findByNickname',
        {'nickname': 'ghost'},
        h.bundle,
      );
      expect(result, isNull);
    });

    test('gameGroup.getAll serialises the list via toJson', () async {
      final h = _bundle();
      // Prime via the repo's own API so its internal indices are right.
      await h.gameGroup.create({
        'gameGroupId': 'g-1',
        'userId': 'u-1',
        'role': GameGroupRole.admin.name,
      });

      final result = await dispatcher.dispatch(
        'repo.gameGroup.getAll',
        {'userId': 'u-1'},
        h.bundle,
      );
      expect(result, isA<List>());
    });
  });

  group('routing — write methods', () {
    test('user.save round-trips via fromJson and toJson', () async {
      final h = _bundle();
      final result = await dispatcher.dispatch(
        'repo.user.save',
        {
          'user': {
            'id': 'u-1',
            'nickname': 'alice',
            'created_at': DateTime(2026, 4, 24).toUtc().toIso8601String(),
          }
        },
        h.bundle,
      );
      expect((result as Map)['id'], 'u-1');
      expect(await h.user.getById('u-1'), isNotNull);
    });

    test('gameGroup.addMember decodes the role enum from its name',
        () async {
      final h = _bundle();
      await dispatcher.dispatch(
        'repo.gameGroup.addMember',
        {
          'gameGroupId': 'g-1',
          'userId': 'u-1',
          'role': 'gm',
        },
        h.bundle,
      );

      final roles = await h.gameGroup.getRolesForUser('g-1', 'u-1');
      expect(roles, contains(GameGroupRole.gm));
    });

    test('void method returns null', () async {
      final h = _bundle();
      // Add member first so removeMember has something to remove.
      await dispatcher.dispatch(
        'repo.gameGroup.addMember',
        {'gameGroupId': 'g-1', 'userId': 'u-1', 'role': 'player'},
        h.bundle,
      );
      final result = await dispatcher.dispatch(
        'repo.gameGroup.removeMember',
        {'gameGroupId': 'g-1', 'userId': 'u-1', 'role': 'player'},
        h.bundle,
      );
      expect(result, isNull);
    });
  });

  group('rejections', () {
    test('stream methods throw UnsupportedError pointing at Phase 5',
        () async {
      final h = _bundle();
      await expectLater(
        () => dispatcher.dispatch(
            'repo.userTask.watchForAssignee', {'assigneeId': 'u'}, h.bundle),
        throwsA(isA<UnsupportedError>()
            .having((e) => e.message, 'message', contains('Phase 5'))),
      );
    });

    test('avatar bytes upload is rejected with a Storage hint', () async {
      final h = _bundle();
      await expectLater(
        () => dispatcher.dispatch(
            'repo.user.uploadAvatar', {'userId': 'u', 'bytes': []}, h.bundle),
        throwsA(isA<UnsupportedError>()
            .having((e) => e.message, 'message', contains('signed URLs'))),
      );
    });

    test('unknown method type throws ArgumentError', () async {
      final h = _bundle();
      await expectLater(
        () => dispatcher.dispatch('repo.user.flyToTheMoon', {}, h.bundle),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('missing required string arg throws ArgumentError', () async {
      final h = _bundle();
      await expectLater(
        () => dispatcher.dispatch('repo.user.findByNickname', {}, h.bundle),
        throwsA(isA<ArgumentError>()
            .having((e) => e.message, 'message', contains('nickname'))),
      );
    });

    test('non-string for required string arg throws', () async {
      final h = _bundle();
      await expectLater(
        () => dispatcher.dispatch(
            'repo.user.findByNickname', {'nickname': 42}, h.bundle),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('serialisation specifics', () {
    test('getMembersWithProfiles flattens tuples to {membership, user}',
        () async {
      final h = _bundle();
      await h.gameGroup.create({
        'gameGroupId': 'g-1',
        'userId': 'u-1',
        'role': GameGroupRole.player.name,
      });

      final result = await dispatcher.dispatch(
        'repo.gameGroup.getMembersWithProfiles',
        {'gameGroupId': 'g-1'},
        h.bundle,
      );
      expect(result, isA<List>());
      final entries = (result as List).cast<Map<String, dynamic>>();
      expect(entries.single.keys, containsAll(['membership', 'user']));
    });

    test('getRolesForUser maps roles to their names', () async {
      final h = _bundle();
      await h.gameGroup.create({
        'gameGroupId': 'g-1',
        'userId': 'u-1',
        'role': GameGroupRole.admin.name,
      });

      final result = await dispatcher.dispatch(
        'repo.gameGroup.getRolesForUser',
        {'gameGroupId': 'g-1', 'userId': 'u-1'},
        h.bundle,
      );
      expect(result, ['admin']);
    });
  });
}
