import '../rba/rba_factory.dart';
import 'authenticated_connection.dart';
import 'auth_token_validator.dart';
import 'message_handler.dart';

/// Default upper bound on concurrent connections that have not yet
/// presented an `auth` frame. Tuned for "hundreds of users" expected
/// concurrency; raise on busier deployments.
const int kDefaultAwaitingAuthLimit = 256;

/// Default authentication grace period — connections that do not
/// authenticate within this window are closed.
const Duration kDefaultAuthTimeout = Duration(seconds: 8);

/// Bookkeeping around [AuthenticatedConnection] lifecycles. Caps the
/// number of concurrent unauthenticated connections; once that pool is
/// full further connect attempts are closed immediately by [accept].
/// Authenticated connections do not consume slots — the pool exists so
/// a flood of unauthenticated peers cannot starve legitimate clients.
class ConnectionManager {
  final IAuthTokenValidator _validator;
  final RbaFactory _rba;
  final MessageHandler _messageHandler;
  final int _awaitingAuthLimit;
  final Duration _authTimeout;

  int _awaitingAuth = 0;

  ConnectionManager({
    required IAuthTokenValidator validator,
    required RbaFactory rba,
    required MessageHandler messageHandler,
    int awaitingAuthLimit = kDefaultAwaitingAuthLimit,
    Duration authTimeout = kDefaultAuthTimeout,
  })  : _validator = validator,
        _rba = rba,
        _messageHandler = messageHandler,
        _awaitingAuthLimit = awaitingAuthLimit,
        _authTimeout = authTimeout;

  /// Current count of connections still awaiting their `auth` frame.
  int get awaitingAuth => _awaitingAuth;

  /// Registers a new connection. Returns the [AuthenticatedConnection]
  /// driving its lifecycle, or `null` if the awaiting-auth pool is
  /// full — in that case the caller should close the connection (the
  /// manager already did via [close]).
  AuthenticatedConnection? accept({
    required Stream<dynamic> incoming,
    required void Function(String) send,
    required Future<void> Function() close,
  }) {
    if (_awaitingAuth >= _awaitingAuthLimit) {
      close();
      return null;
    }
    _awaitingAuth++;
    return AuthenticatedConnection(
      incoming: incoming,
      send: send,
      close: close,
      validator: _validator,
      bundleFor: (p) => _rba.forPrincipal(p),
      messageHandler: _messageHandler,
      authTimeout: _authTimeout,
      onAuthSlotReleased: _releaseSlot,
    );
  }

  void _releaseSlot() {
    if (_awaitingAuth > 0) _awaitingAuth--;
  }
}
