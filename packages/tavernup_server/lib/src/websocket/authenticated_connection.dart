import 'dart:async';
import 'dart:convert';

import '../rba/principal.dart';
import '../rba/rba_repository_bundle.dart';
import 'auth_token_validator.dart';
import 'message_handler.dart';

/// Per-connection state machine. Owns one WebSocket's lifecycle: holds
/// the principal once authenticated, drives the auth-frame handshake,
/// rejects everything else before auth, and forwards authenticated
/// frames into the [MessageHandler].
///
/// Connection inputs are passed as raw stream + callbacks rather than a
/// `WebSocketChannel` so tests can substitute a `StreamController` and
/// a list collector for the outgoing side without implementing the full
/// channel surface.
class AuthenticatedConnection {
  final Stream<dynamic> _incoming;
  final void Function(String) _send;
  final Future<void> Function() _close;
  final IAuthTokenValidator _validator;
  final RbaRepositoryBundle Function(Principal) _bundleFor;
  final MessageHandler _messageHandler;
  final Duration _authTimeout;
  final void Function() _onAuthSlotReleased;

  Principal? _principal;
  RbaRepositoryBundle? _repos;
  Timer? _authTimer;
  StreamSubscription<dynamic>? _subscription;
  bool _slotReleased = false;

  AuthenticatedConnection({
    required Stream<dynamic> incoming,
    required void Function(String) send,
    required Future<void> Function() close,
    required IAuthTokenValidator validator,
    required RbaRepositoryBundle Function(Principal) bundleFor,
    required MessageHandler messageHandler,
    required Duration authTimeout,
    required void Function() onAuthSlotReleased,
  })  : _incoming = incoming,
        _send = send,
        _close = close,
        _validator = validator,
        _bundleFor = bundleFor,
        _messageHandler = messageHandler,
        _authTimeout = authTimeout,
        _onAuthSlotReleased = onAuthSlotReleased {
    _authTimer = Timer(_authTimeout, _onAuthTimeout);
    _subscription = _incoming.listen(
      _onMessage,
      onError: (_) => _cleanup(),
      onDone: _cleanup,
    );
  }

  /// True once the connection holds an authenticated principal.
  bool get isAuthenticated => _principal != null;

  void _onAuthTimeout() {
    if (_principal != null) return;
    unawaited(_close());
  }

  Future<void> _onMessage(dynamic raw) async {
    if (raw is! String) return;
    final json = _safeDecode(raw);
    if (json == null) {
      _send(_errorResponse(null, 'Invalid JSON'));
      return;
    }

    if (_principal == null) {
      await _handleAuth(json);
      return;
    }

    final response = await _messageHandler.handle(raw, _repos!);
    _send(response);
  }

  Future<void> _handleAuth(Map<String, dynamic> json) async {
    final requestId = json['requestId'] as String?;
    if (json['type'] != 'auth') {
      _send(_errorResponse(requestId, 'Authentication required'));
      return;
    }
    final payload = json['payload'] as Map<String, dynamic>?;
    final token = payload?['token'] as String?;
    if (token == null) {
      _send(_errorResponse(requestId, 'Missing token'));
      return;
    }
    final result = await _validator.validate(token);
    switch (result) {
      case TokenValid(:final userId):
        _principal = UserPrincipal(userId);
        _repos = _bundleFor(_principal!);
        _authTimer?.cancel();
        _releaseSlot();
        _send(_successResponse(requestId, {'userId': userId}));
      case TokenInvalid(:final reason):
        _send(_errorResponse(requestId, 'Auth failed: $reason'));
    }
  }

  void _cleanup() {
    _authTimer?.cancel();
    unawaited(_subscription?.cancel());
    _subscription = null;
    _releaseSlot();
  }

  void _releaseSlot() {
    if (_slotReleased) return;
    _slotReleased = true;
    _onAuthSlotReleased();
  }

  Map<String, dynamic>? _safeDecode(String raw) {
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  String _successResponse(String? requestId, Map<String, dynamic> data) =>
      jsonEncode({'requestId': requestId, 'success': true, 'data': data});

  String _errorResponse(String? requestId, String error) =>
      jsonEncode({'requestId': requestId, 'success': false, 'error': error});
}
