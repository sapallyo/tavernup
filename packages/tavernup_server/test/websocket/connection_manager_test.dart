import 'dart:async';

import 'package:tavernup_domain/tavernup_domain.dart';
import 'package:test/test.dart';

import 'package:tavernup_server/src/rba/principal.dart';
import 'package:tavernup_server/src/rba/rba_factory.dart';
import 'package:tavernup_server/src/rba/rba_repository_bundle.dart';
import 'package:tavernup_server/src/websocket/auth_token_validator.dart';
import 'package:tavernup_server/src/websocket/connection_manager.dart';
import 'package:tavernup_server/src/websocket/message_handler.dart';

class _FakeValidator implements IAuthTokenValidator {
  final TokenValidationResult result;
  _FakeValidator(this.result);

  @override
  Future<TokenValidationResult> validate(String token) async => result;
}

/// Reaches inside RbaFactory only to obtain a fresh instance for tests.
/// In production the factory is constructed via fromEnvironment.
class _StubRbaFactory implements RbaFactory {
  final RbaRepositoryBundle _bundle;
  _StubRbaFactory(this._bundle);

  @override
  RbaRepositoryBundle forPrincipal(Principal principal) => _bundle;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ConnectionManager _manager({
  required TokenValidationResult validatorResult,
  int awaitingAuthLimit = 3,
  Duration authTimeout = const Duration(seconds: 5),
}) {
  return ConnectionManager(
    validator: _FakeValidator(validatorResult),
    rba: _StubRbaFactory(RbaRepositoryBundle(
      user: MockUserRepository(),
      character: MockCharacterRepository(),
      gameGroup: MockGameGroupRepository(),
      invitation: MockInvitationRepository(),
      storyNode: MockStoryNodeRepository(),
      storyNodeInstance: MockStoryNodeInstanceRepository(),
      session: MockSessionRepository(),
      userTask: MockUserTaskRepository(),
    )),
    messageHandler: MessageHandler(completeUserTask: (_, __) async {}),
    awaitingAuthLimit: awaitingAuthLimit,
    authTimeout: authTimeout,
  );
}

({StreamController<dynamic> controller, Future<void> Function() close,
  bool Function() wasClosed})
    _stub() {
  final controller = StreamController<dynamic>.broadcast();
  var closed = false;
  return (
    controller: controller,
    close: () async {
      closed = true;
      if (!controller.isClosed) await controller.close();
    },
    wasClosed: () => closed,
  );
}

void main() {
  test('awaitingAuth increments on accept and decrements on auth success',
      () async {
    final m = _manager(validatorResult: const TokenValid('user-42'));
    final s = _stub();

    final conn = m.accept(
      incoming: s.controller.stream,
      send: (_) {},
      close: s.close,
    );
    expect(conn, isNotNull);
    expect(m.awaitingAuth, 1);

    s.controller.add('{"type":"auth","requestId":"r","payload":{"token":"t"}}');
    await Future<void>.delayed(Duration.zero);

    expect(m.awaitingAuth, 0);
  });

  test('awaitingAuth decrements when an unauthenticated connection closes',
      () async {
    final m = _manager(validatorResult: const TokenInvalid('x'));
    final s = _stub();

    m.accept(
      incoming: s.controller.stream,
      send: (_) {},
      close: s.close,
    );
    expect(m.awaitingAuth, 1);

    await s.controller.close();
    await Future<void>.delayed(Duration.zero);

    expect(m.awaitingAuth, 0);
  });

  test('accept rejects new connections when pool is full', () async {
    final m = _manager(
      validatorResult: const TokenValid('u'),
      awaitingAuthLimit: 2,
    );
    final s1 = _stub();
    final s2 = _stub();
    final overflow = _stub();

    m.accept(
        incoming: s1.controller.stream, send: (_) {}, close: s1.close);
    m.accept(
        incoming: s2.controller.stream, send: (_) {}, close: s2.close);
    final rejected = m.accept(
      incoming: overflow.controller.stream,
      send: (_) {},
      close: overflow.close,
    );

    expect(rejected, isNull);
    await Future<void>.delayed(Duration.zero);
    expect(overflow.wasClosed(), isTrue);
    expect(m.awaitingAuth, 2);
  });

  test('authenticated connections do not occupy a slot any longer',
      () async {
    final m = _manager(
      validatorResult: const TokenValid('user-42'),
      awaitingAuthLimit: 1,
    );

    // First connection authenticates -> frees its slot.
    final s1 = _stub();
    m.accept(
        incoming: s1.controller.stream, send: (_) {}, close: s1.close);
    s1.controller.add('{"type":"auth","requestId":"r","payload":{"token":"t"}}');
    await Future<void>.delayed(Duration.zero);
    expect(m.awaitingAuth, 0);

    // Second connection now fits in the same slot.
    final s2 = _stub();
    final conn2 = m.accept(
      incoming: s2.controller.stream,
      send: (_) {},
      close: s2.close,
    );
    expect(conn2, isNotNull);
    expect(m.awaitingAuth, 1);
  });
}
