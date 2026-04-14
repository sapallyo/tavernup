import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'message_handler.dart';

/// WebSocket server that accepts client connections and dispatches
/// incoming messages to [MessageHandler].
///
/// Each connected client gets its own channel. Messages are processed
/// sequentially per client.
class WebSocketServer {
  final MessageHandler _messageHandler;

  WebSocketServer(this._messageHandler);

  /// Returns a shelf [Handler] that upgrades HTTP connections to WebSocket.
  Handler get handler => webSocketHandler(_onConnection);

  void _onConnection(WebSocketChannel channel) {
    channel.stream.listen(
      (message) async {
        if (message is! String) return;
        final response = await _messageHandler.handle(message);
        channel.sink.add(response);
      },
      onError: (error) => channel.sink.close(),
      onDone: () => channel.sink.close(),
    );
  }
}
