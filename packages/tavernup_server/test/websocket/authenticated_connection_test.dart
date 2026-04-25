import 'dart:async';
import 'dart:convert';

import 'package:tavernup_domain/tavernup_domain.dart';
import 'package:test/test.dart';

import 'package:tavernup_server/src/rba/principal.dart';
import 'package:tavernup_server/src/rba/rba_factory.dart';
import 'package:tavernup_server/src/rba/rba_repository_bundle.dart';
import 'package:tavernup_server/src/websocket/authenticated_connection.dart';
import 'package:tavernup_server/src/websocket/auth_token_validator.dart';
import 'package:tavernup_server/src/websocket/message_handler.dart';
import 'package:tavernup_server/src/websocket/subscription_manager.dart';

class _FakeValidator implements IAuthTokenValidator {
  final TokenValidationResult Function(String token) _resolve;
  _FakeValidator(this._resolve);

  @override
  Future<TokenValidationResult> validate(String token) async =>
      _resolve(token);
}

class _StubFactory implements RbaFactory {
  final RbaRepositoryBundle _bundle;
  _StubFactory(this._bundle);
  @override
  RbaRepositoryBundle forPrincipal(Principal p) => _bundle;
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

RbaRepositoryBundle _bundle({IUserRepository? user}) {
  final userRepo = user ?? MockUserRepository();
  return RbaRepositoryBundle(
    user: userRepo,
    character: MockCharacterRepository(),
    gameGroup: MockGameGroupRepository(),
    invitation: MockInvitationRepository(),
    storyNode: MockStoryNodeRepository(),
    storyNodeInstance: MockStoryNodeInstanceRepository(),
    session: MockSessionRepository(),
    userTask: MockUserTaskRepository(),
  );
}

class _Harness {
  final controller = StreamController<dynamic>.broadcast();
  final outgoing = <String>[];
  bool closed = false;
  int slotReleases = 0;

  late AuthenticatedConnection connection;

  _Harness({
    required IAuthTokenValidator validator,
    Duration authTimeout = const Duration(seconds: 5),
    RbaRepositoryBundle? bundle,
    SubscriptionManager? subscriptions,
  }) {
    final caughtBundle = bundle ?? _bundle();
    connection = AuthenticatedConnection(
      incoming: controller.stream,
      send: outgoing.add,
      close: () async {
        closed = true;
      },
      validator: validator,
      bundleFor: (p) => caughtBundle,
      messageHandler: MessageHandler(
        completeUserTask: (_, __) async {},
      ),
      subscriptions: subscriptions,
      authTimeout: authTimeout,
      onAuthSlotReleased: () => slotReleases++,
    );
  }

  Future<void> send(Map<String, dynamic> frame) async {
    controller.add(jsonEncode(frame));
    await Future<void>.delayed(Duration.zero);
  }

  Map<String, dynamic> get lastResponse =>
      jsonDecode(outgoing.last) as Map<String, dynamic>;
}

void main() {
  test('rejects non-auth frames before authentication', () async {
    final h = _Harness(validator: _FakeValidator((_) => const TokenValid('u')));
    await h.send({
      'type': 'validate-user',
      'requestId': 'r1',
      'payload': {'nickname': 'x'},
    });
    expect(h.lastResponse['success'], isFalse);
    expect(h.lastResponse['error'], contains('Authentication required'));
    expect(h.connection.isAuthenticated, isFalse);
  });

  test('accepts a valid auth frame and binds the principal', () async {
    final h = _Harness(
      validator: _FakeValidator((token) =>
          token == 'good' ? const TokenValid('user-42') : const TokenInvalid('nope')),
    );
    await h.send({
      'type': 'auth',
      'requestId': 'r1',
      'payload': {'token': 'good'},
    });
    expect(h.lastResponse['success'], isTrue);
    expect(h.lastResponse['data']['userId'], 'user-42');
    expect(h.connection.isAuthenticated, isTrue);
    expect(h.slotReleases, 1);
  });

  test('rejects an invalid auth token without binding a principal',
      () async {
    final h = _Harness(
      validator: _FakeValidator((_) => const TokenInvalid('bad')),
    );
    await h.send({
      'type': 'auth',
      'requestId': 'r1',
      'payload': {'token': 'wrong'},
    });
    expect(h.lastResponse['success'], isFalse);
    expect(h.lastResponse['error'], contains('Auth failed'));
    expect(h.connection.isAuthenticated, isFalse);
    expect(h.slotReleases, 0);
  });

  test('forwards authenticated frames to the message handler', () async {
    final user = User(
      id: 'user-42',
      nickname: 'alice',
      createdAt: DateTime(2026, 4, 24),
    );
    final userRepo = MockUserRepository()..seed([user]);
    final h = _Harness(
      validator: _FakeValidator((_) => const TokenValid('user-42')),
      bundle: _bundle(user: userRepo),
    );
    await h.send({
      'type': 'auth',
      'requestId': 'r1',
      'payload': {'token': 'good'},
    });

    await h.send({
      'type': 'validate-user',
      'requestId': 'r2',
      'payload': {'nickname': 'alice'},
    });

    expect(h.lastResponse['requestId'], 'r2');
    expect(h.lastResponse['success'], isTrue);
    expect(h.lastResponse['data']['userId'], 'user-42');
  });

  test('auth timeout closes the connection if no auth frame arrives',
      () async {
    final h = _Harness(
      validator: _FakeValidator((_) => const TokenValid('u')),
      authTimeout: const Duration(milliseconds: 30),
    );
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(h.closed, isTrue);
    expect(h.connection.isAuthenticated, isFalse);
  });

  test('auth timeout does not fire after successful authentication',
      () async {
    final h = _Harness(
      validator: _FakeValidator((_) => const TokenValid('user-42')),
      authTimeout: const Duration(milliseconds: 30),
    );
    await h.send({
      'type': 'auth',
      'requestId': 'r1',
      'payload': {'token': 'good'},
    });
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(h.closed, isFalse);
  });

  test('connection close releases the auth slot at most once', () async {
    final h = _Harness(
      validator: _FakeValidator((_) => const TokenValid('user-42')),
    );
    await h.controller.close();
    await Future<void>.delayed(Duration.zero);
    expect(h.slotReleases, 1);
  });

  test('successful auth then close still releases the slot exactly once',
      () async {
    final h = _Harness(
      validator: _FakeValidator((_) => const TokenValid('user-42')),
    );
    await h.send({
      'type': 'auth',
      'requestId': 'r1',
      'payload': {'token': 'good'},
    });
    expect(h.slotReleases, 1);

    await h.controller.close();
    await Future<void>.delayed(Duration.zero);
    expect(h.slotReleases, 1);
  });

  test('malformed JSON before auth gets an Invalid JSON response',
      () async {
    final h = _Harness(validator: _FakeValidator((_) => const TokenValid('u')));
    h.controller.add('not json');
    await Future<void>.delayed(Duration.zero);
    expect(h.lastResponse['success'], isFalse);
    expect(h.lastResponse['error'], contains('Invalid JSON'));
  });

  test('auth frame missing token is rejected', () async {
    final h = _Harness(validator: _FakeValidator((_) => const TokenValid('u')));
    await h.send({
      'type': 'auth',
      'requestId': 'r1',
      'payload': {},
    });
    expect(h.lastResponse['success'], isFalse);
    expect(h.lastResponse['error'], contains('Missing token'));
    expect(h.connection.isAuthenticated, isFalse);
  });

  group('stream subscriptions', () {
    Future<_Harness> authenticated({
      required SubscriptionManager subscriptions,
      RbaRepositoryBundle? bundle,
    }) async {
      final h = _Harness(
        validator: _FakeValidator((_) => const TokenValid('user-1')),
        bundle: bundle,
        subscriptions: subscriptions,
      );
      await h.send({
        'type': 'auth',
        'requestId': 'r0',
        'payload': {'token': 'good'},
      });
      h.outgoing.clear();
      return h;
    }

    test('stream-subscribe registers and stream-event frames are sent',
        () async {
      final userTask = MockUserTaskRepository();
      final bundle = _bundle()..userTask;
      final wrapped = RbaRepositoryBundle(
        user: bundle.user,
        character: bundle.character,
        gameGroup: bundle.gameGroup,
        invitation: bundle.invitation,
        storyNode: bundle.storyNode,
        storyNodeInstance: bundle.storyNodeInstance,
        session: bundle.session,
        userTask: userTask,
      );
      final mgr = SubscriptionManager(_StubFactory(wrapped));
      final h = await authenticated(subscriptions: mgr, bundle: wrapped);

      await h.send({
        'type': 'stream-subscribe',
        'requestId': 'r1',
        'payload': {
          'streamId': 's-1',
          'repoName': 'userTask',
          'method': 'watchForAssignee',
          'args': {'assigneeId': 'user-1'},
        },
      });
      expect(h.lastResponse['success'], isTrue);
      expect(h.lastResponse['data']['streamId'], 's-1');
      expect(h.connection.activeStreamCount, 1);

      await userTask.create(UserTask(
        id: 't-1',
        name: 'accept-invitation',
        processInstanceId: 'pi-1',
        variables: const {},
        assignee: 'user-1',
        created: DateTime(2026, 4, 24, 12),
      ));
      await Future<void>.delayed(Duration.zero);

      final events = h.outgoing
          .map((s) => jsonDecode(s) as Map<String, dynamic>)
          .where((m) => m['type'] == 'stream-event')
          .toList();
      expect(events, hasLength(1));
      expect(events.single['payload']['streamId'], 's-1');
      final list = events.single['payload']['data'] as List;
      expect((list.single as Map)['id'], 't-1');
    });

    test('stream-unsubscribe stops further events', () async {
      final userTask = MockUserTaskRepository();
      final bundle = RbaRepositoryBundle(
        user: MockUserRepository(),
        character: MockCharacterRepository(),
        gameGroup: MockGameGroupRepository(),
        invitation: MockInvitationRepository(),
        storyNode: MockStoryNodeRepository(),
        storyNodeInstance: MockStoryNodeInstanceRepository(),
        session: MockSessionRepository(),
        userTask: userTask,
      );
      final mgr = SubscriptionManager(_StubFactory(bundle));
      final h = await authenticated(subscriptions: mgr, bundle: bundle);

      await h.send({
        'type': 'stream-subscribe',
        'requestId': 'r1',
        'payload': {
          'streamId': 's-1',
          'repoName': 'userTask',
          'method': 'watchForAssignee',
          'args': {'assigneeId': 'user-1'},
        },
      });
      await h.send({
        'type': 'stream-unsubscribe',
        'requestId': 'r2',
        'payload': {'streamId': 's-1'},
      });
      expect(h.connection.activeStreamCount, 0);
      expect(mgr.upstreamCount, 0);

      h.outgoing.clear();
      await userTask.create(UserTask(
        id: 't-1',
        name: 'accept-invitation',
        processInstanceId: 'pi-1',
        variables: const {},
        assignee: 'user-1',
        created: DateTime(2026, 4, 24, 12),
      ));
      await Future<void>.delayed(Duration.zero);

      final events = h.outgoing
          .map((s) => jsonDecode(s) as Map<String, dynamic>)
          .where((m) => m['type'] == 'stream-event')
          .toList();
      expect(events, isEmpty);
    });

    test('connection close releases all stream subscriptions', () async {
      final bundle = _bundle();
      final mgr = SubscriptionManager(_StubFactory(bundle));
      final h = await authenticated(subscriptions: mgr, bundle: bundle);

      await h.send({
        'type': 'stream-subscribe',
        'requestId': 'r1',
        'payload': {
          'streamId': 's-1',
          'repoName': 'userTask',
          'method': 'watchForAssignee',
          'args': {'assigneeId': 'user-1'},
        },
      });
      await h.send({
        'type': 'stream-subscribe',
        'requestId': 'r2',
        'payload': {
          'streamId': 's-2',
          'repoName': 'userTask',
          'method': 'watchForAssignee',
          'args': {'assigneeId': 'user-2'},
        },
      });
      expect(h.connection.activeStreamCount, 2);
      expect(mgr.upstreamCount, 2);

      await h.controller.close();
      await Future<void>.delayed(Duration.zero);

      expect(h.connection.activeStreamCount, 0);
      expect(mgr.upstreamCount, 0);
    });

    test('stream-subscribe without a configured manager is rejected',
        () async {
      final h = _Harness(
          validator: _FakeValidator((_) => const TokenValid('user-1')));
      await h.send({
        'type': 'auth',
        'requestId': 'r0',
        'payload': {'token': 'good'},
      });
      h.outgoing.clear();

      await h.send({
        'type': 'stream-subscribe',
        'requestId': 'r1',
        'payload': {
          'streamId': 's-1',
          'repoName': 'userTask',
          'method': 'watchForAssignee',
          'args': {'assigneeId': 'user-1'},
        },
      });
      expect(h.lastResponse['success'], isFalse);
      expect(h.lastResponse['error'], contains('not configured'));
    });

    test('stream-subscribe with a missing field is rejected', () async {
      final mgr = SubscriptionManager(_StubFactory(_bundle()));
      final h = await authenticated(subscriptions: mgr);

      await h.send({
        'type': 'stream-subscribe',
        'requestId': 'r1',
        'payload': {
          'streamId': 's-1',
          // missing repoName
          'method': 'watchForAssignee',
          'args': {'assigneeId': 'user-1'},
        },
      });
      expect(h.lastResponse['success'], isFalse);
      expect(h.lastResponse['error'], contains('Missing'));
    });

    test('stream-subscribe with a duplicate streamId is rejected',
        () async {
      final mgr = SubscriptionManager(_StubFactory(_bundle()));
      final h = await authenticated(subscriptions: mgr);

      Future<void> subscribe(String requestId) => h.send({
            'type': 'stream-subscribe',
            'requestId': requestId,
            'payload': {
              'streamId': 's-1',
              'repoName': 'userTask',
              'method': 'watchForAssignee',
              'args': {'assigneeId': 'user-1'},
            },
          });

      await subscribe('r1');
      await subscribe('r2');
      expect(h.lastResponse['success'], isFalse);
      expect(h.lastResponse['error'], contains('already in use'));
    });

    test('stream-unsubscribe with an unknown streamId is rejected',
        () async {
      final mgr = SubscriptionManager(_StubFactory(_bundle()));
      final h = await authenticated(subscriptions: mgr);

      await h.send({
        'type': 'stream-unsubscribe',
        'requestId': 'r1',
        'payload': {'streamId': 'never-existed'},
      });
      expect(h.lastResponse['success'], isFalse);
      expect(h.lastResponse['error'], contains('Unknown streamId'));
    });
  });
}
