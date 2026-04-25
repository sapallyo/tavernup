import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'connection_manager.dart';

/// Adapts shelf's WebSocket upgrade into the [ConnectionManager] flow.
///
/// On connect it hands the channel's stream and sink to
/// `ConnectionManager.accept`, which either spins up an
/// [AuthenticatedConnection] for the client or — if the awaiting-auth
/// pool is full — closes the channel immediately.
class WebSocketServer {
  final ConnectionManager _connectionManager;

  WebSocketServer(this._connectionManager);

  Handler get handler => webSocketHandler(_onConnection);

  void _onConnection(WebSocketChannel channel) {
    _connectionManager.accept(
      incoming: channel.stream,
      send: (data) => channel.sink.add(data),
      close: () => channel.sink.close(),
    );
  }
}
