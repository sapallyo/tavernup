import 'package:tavernup_domain/tavernup_domain.dart';
import 'package:tavernup_repositories_remote/tavernup_repositories_remote.dart';
import 'package:test/test.dart';

void main() {
  late MockRealtimeTransport transport;

  setUp(() {
    transport = MockRealtimeTransport();
  });

  tearDown(() => transport.dispose());

  group('RemoteUserRepository', () {
    test('getById sends repo.user.getById and decodes the result',
        () async {
      final repo = RemoteUserRepository(transport);

      final future = repo.getById('u-1');
      await Future<void>.delayed(Duration.zero);

      expect(transport.sentRequests, hasLength(1));
      expect(transport.sentRequests.single.type, 'repo.user.getById');
      expect(transport.sentRequests.single.payload, {'userId': 'u-1'});

      transport.respondTo('repo.user.getById', {
        'result': {
          'id': 'u-1',
          'nickname': 'alice',
          'created_at': DateTime(2026, 4, 24).toUtc().toIso8601String(),
        },
      });

      final user = await future;
      expect(user, isNotNull);
      expect(user!.id, 'u-1');
      expect(user.nickname, 'alice');
    });

    test('getById returns null when result is null', () async {
      final repo = RemoteUserRepository(transport);

      final future = repo.getById('ghost');
      await Future<void>.delayed(Duration.zero);
      transport.respondTo('repo.user.getById', {'result': null});

      expect(await future, isNull);
    });

    test('save round-trips the user via toJson/fromJson', () async {
      final repo = RemoteUserRepository(transport);
      final user = User(
        id: 'u-1',
        nickname: 'alice',
        createdAt: DateTime(2026, 4, 24).toUtc(),
      );

      final future = repo.save(user);
      await Future<void>.delayed(Duration.zero);

      final sent = transport.sentRequests.single;
      expect(sent.type, 'repo.user.save');
      expect(sent.payload['user'], user.toJson());

      transport.respondTo('repo.user.save', {
        'result': {
          ...user.toJson(),
          'created_at': user.createdAt.toIso8601String(),
        },
      });
      final saved = await future;
      expect(saved.id, 'u-1');
    });

    test('createAvatarUploadUrl decodes record fields', () async {
      final repo = RemoteUserRepository(transport);

      final future = repo.createAvatarUploadUrl(
        userId: 'u-1',
        contentType: 'image/png',
      );
      await Future<void>.delayed(Duration.zero);

      transport.respondTo('repo.user.createAvatarUploadUrl', {
        'result': {
          'uploadUrl': 'https://storage.example/abc',
          'path': 'u-1/avatar',
        },
      });
      final result = await future;
      expect(result.uploadUrl, 'https://storage.example/abc');
      expect(result.path, 'u-1/avatar');
    });
  });

  group('RemoteCharacterRepository', () {
    test('getOwned sends correct request and decodes the list', () async {
      final repo = RemoteCharacterRepository(transport);

      final future = repo.getOwned('owner-1');
      await Future<void>.delayed(Duration.zero);

      transport.respondTo('repo.character.getOwned', {
        'result': [
          {
            'id': 'c-1',
            'owner_id': 'owner-1',
            'name': 'Aria',
            'system_key': 'sr5',
            'custom_data': <String, dynamic>{},
            'visible_to': <String>[],
          }
        ]
      });

      final chars = await future;
      expect(chars, hasLength(1));
      expect(chars.single.id, 'c-1');
    });

    test('watchOwned subscribes via the stream protocol and decodes events',
        () async {
      final repo = RemoteCharacterRepository(transport);

      final received = <List<Character>>[];
      final sub = repo.watchOwned('owner-1').listen(received.add);
      await Future<void>.delayed(Duration.zero);

      transport.simulateStreamEvent(
        repoName: 'character',
        method: 'watchOwned',
        args: const {'ownerId': 'owner-1'},
        data: [
          {
            'id': 'c-1',
            'owner_id': 'owner-1',
            'name': 'Aria',
            'system_key': 'sr5',
            'custom_data': <String, dynamic>{},
            'visible_to': <String>[],
          }
        ],
      );
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received.single.single.id, 'c-1');
      await sub.cancel();
    });
  });

  group('RemoteGameGroupRepository', () {
    test('addMember encodes the role enum as its name', () async {
      final repo = RemoteGameGroupRepository(transport);

      final future = repo.addMember('g-1', 'u-1', GameGroupRole.gm);
      await Future<void>.delayed(Duration.zero);

      final sent = transport.sentRequests.single;
      expect(sent.type, 'repo.gameGroup.addMember');
      expect(sent.payload, {
        'gameGroupId': 'g-1',
        'userId': 'u-1',
        'role': 'gm',
      });
      transport.respondTo('repo.gameGroup.addMember', {'result': null});
      await future;
    });

    test('getMembersWithProfiles unflattens server tuples', () async {
      final repo = RemoteGameGroupRepository(transport);
      final future = repo.getMembersWithProfiles('g-1');
      await Future<void>.delayed(Duration.zero);

      transport.respondTo('repo.gameGroup.getMembersWithProfiles', {
        'result': [
          {
            'membership': {
              'id': 'm-1',
              'game_group_id': 'g-1',
              'user_id': 'u-1',
              'role': 'player',
              'joined_at':
                  DateTime(2026, 4, 24).toUtc().toIso8601String(),
            },
            'user': {
              'id': 'u-1',
              'nickname': 'alice',
              'created_at':
                  DateTime(2026, 4, 24).toUtc().toIso8601String(),
            },
          },
        ]
      });

      final pairs = await future;
      expect(pairs.single.$1.userId, 'u-1');
      expect(pairs.single.$2!.nickname, 'alice');
    });
  });

  group('RemoteUserTaskRepository', () {
    test('watchForAssignee decodes tasks (variables included)', () async {
      final repo = RemoteUserTaskRepository(transport);

      final received = <List<UserTask>>[];
      final sub = repo.watchForAssignee('user-1').listen(received.add);
      await Future<void>.delayed(Duration.zero);

      transport.simulateStreamEvent(
        repoName: 'userTask',
        method: 'watchForAssignee',
        args: const {'assigneeId': 'user-1'},
        data: [
          {
            'id': 't-1',
            'name': 'accept-invitation',
            'processInstanceId': 'pi-1',
            'assignee': 'user-1',
            'created': DateTime(2026, 4, 24, 12).toIso8601String(),
            'variables': {
              'inviter': {'type': 'string', 'value': 'bob'},
            },
          }
        ],
      );
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received.single.single.id, 't-1');
      expect(received.single.single.variables['inviter'],
          Variable.string('bob'));
      await sub.cancel();
    });

    test('create throws — server-internal call', () async {
      final repo = RemoteUserTaskRepository(transport);
      expect(
        () => repo.create(UserTask(
          id: 't-1',
          name: 'accept-invitation',
          processInstanceId: 'pi-1',
          variables: const {},
          assignee: 'u',
          created: DateTime(2026, 4, 24),
        )),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
