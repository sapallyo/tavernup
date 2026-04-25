import 'dart:async';
import 'dart:convert';

import '../rba/principal.dart';
import '../rba/rba_repository_bundle.dart';
import 'auth_token_validator.dart';
import 'message_handler.dart';
import 'subscription_manager.dart';

/// Per-connection state machine. Owns one WebSocket's lifecycle: holds
/// the principal once authenticated, drives the auth-frame handshake,
/// rejects everything else before auth, forwards authenticated
/// request/response frames into the [MessageHandler], and manages
/// stream subscriptions for the lifetime of the socket.
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
  final SubscriptionManager? _subscriptions;
  final Duration _authTimeout;
  final void Function() _onAuthSlotReleased;

  Principal? _principal;
  RbaRepositoryBundle? _repos;
  Timer? _authTimer;
  StreamSubscription<dynamic>? _subscription;
  bool _slotReleased = false;

  /// Active stream subscriptions keyed by streamId. The value is the
  /// unsubscribe callback returned from the [SubscriptionManager].
  final Map<String, void Function()> _activeSubscriptions = {};

  AuthenticatedConnection({
    required Stream<dynamic> incoming,
    required void Function(String) send,
    required Future<void> Function() close,
    required IAuthTokenValidator validator,
    required RbaRepositoryBundle Function(Principal) bundleFor,
    required MessageHandler messageHandler,
    required Duration authTimeout,
    required void Function() onAuthSlotReleased,
    SubscriptionManager? subscriptions,
  })  : _incoming = incoming,
        _send = send,
        _close = close,
        _validator = validator,
        _bundleFor = bundleFor,
        _messageHandler = messageHandler,
        _subscriptions = subscriptions,
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

  /// Number of active stream subscriptions on this connection.
  int get activeStreamCount => _activeSubscriptions.length;

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

    final type = json['type'];
    if (type == 'stream-subscribe') {
      _handleStreamSubscribe(json);
      return;
    }
    if (type == 'stream-unsubscribe') {
      _handleStreamUnsubscribe(json);
      return;
    }

    final response = await _messageHandler.handle(raw, _repos!);
    _send(response);
  }

  void _handleStreamSubscribe(Map<String, dynamic> json) {
    final requestId = json['requestId'] as String?;
    if (_subscriptions == null) {
      _send(_errorResponse(requestId,
          'Stream subscriptions are not configured on this server'));
      return;
    }
    final payload = json['payload'] as Map<String, dynamic>?;
    final streamId = payload?['streamId'] as String?;
    final repoName = payload?['repoName'] as String?;
    final method = payload?['method'] as String?;
    final args = payload?['args'] as Map<String, dynamic>? ?? {};
    if (streamId == null || repoName == null || method == null) {
      _send(_errorResponse(
          requestId, 'Missing streamId, repoName, or method'));
      return;
    }
    if (_activeSubscriptions.containsKey(streamId)) {
      _send(_errorResponse(requestId, 'Stream id already in use: $streamId'));
      return;
    }
    try {
      final unsubscribe = _subscriptions.subscribe(
        principal: _principal!,
        repoName: repoName,
        method: method,
        args: args,
        onEvent: (data) => _send(jsonEncode({
          'type': 'stream-event',
          'payload': {'streamId': streamId, 'data': data},
        })),
        onError: (error) => _send(jsonEncode({
          'type': 'stream-error',
          'payload': {'streamId': streamId, 'message': error.toString()},
        })),
        onDone: () {
          _activeSubscriptions.remove(streamId);
          _send(jsonEncode({
            'type': 'stream-done',
            'payload': {'streamId': streamId},
          }));
        },
      );
      _activeSubscriptions[streamId] = unsubscribe;
      _send(_successResponse(requestId, {'streamId': streamId}));
    } catch (e) {
      _send(_errorResponse(requestId, e.toString()));
    }
  }

  void _handleStreamUnsubscribe(Map<String, dynamic> json) {
    final requestId = json['requestId'] as String?;
    final payload = json['payload'] as Map<String, dynamic>?;
    final streamId = payload?['streamId'] as String?;
    if (streamId == null) {
      _send(_errorResponse(requestId, 'Missing streamId'));
      return;
    }
    final unsubscribe = _activeSubscriptions.remove(streamId);
    if (unsubscribe == null) {
      _send(_errorResponse(requestId, 'Unknown streamId: $streamId'));
      return;
    }
    unsubscribe();
    _send(_successResponse(requestId, {'streamId': streamId}));
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
    for (final unsubscribe in _activeSubscriptions.values) {
      unsubscribe();
    }
    _activeSubscriptions.clear();
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
