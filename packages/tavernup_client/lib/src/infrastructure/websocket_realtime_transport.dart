import 'dart:async';
import 'dart:convert';

import 'package:tavernup_domain/tavernup_domain.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Minimal bidirectional byte-channel used by [WebSocketRealtimeTransport].
///
/// Exists so tests can substitute a fake connection without implementing
/// the full [WebSocketChannel] interface. Production uses
/// [_WebSocketChannelAdapter], which wraps a real [WebSocketChannel].
abstract class WebSocketConnection {
  Stream<dynamic> get stream;
  Future<void> get ready;
  void send(String data);
  Future<void> close();
}

class _WebSocketChannelAdapter implements WebSocketConnection {
  final WebSocketChannel _channel;
  _WebSocketChannelAdapter(this._channel);
  @override
  Stream<dynamic> get stream => _channel.stream;
  @override
  Future<void> get ready => _channel.ready;
  @override
  void send(String data) => _channel.sink.add(data);
  @override
  Future<void> close() => _channel.sink.close();
}

/// WebSocket-backed implementation of [IRealtimeTransport].
///
/// Speaks the requestId protocol of `tavernup_server`:
/// - Outgoing requests are tagged with a UUID, the server echoes it in the
///   response, and this transport correlates them via a pending-completers map.
/// - Server-initiated pushes are expected in the shape
///   `{topic: '...', payload: {...}}` and are routed to [subscribe] streams.
///
/// A single WebSocket connection is shared across all subscribers. Reconnect
/// is not handled here — the caller decides when to [connect] / [disconnect].
class WebSocketRealtimeTransport implements IRealtimeTransport {
  final Uri _uri;
  final WebSocketConnection Function(Uri) _connectionFactory;
  final Uuid _uuid;

  WebSocketConnection? _connection;
  StreamSubscription<dynamic>? _incoming;

  final _connectionStateController =
      StreamController<RealtimeConnectionState>.broadcast();
  var _state = RealtimeConnectionState.disconnected;

  final Map<String, Completer<Map<String, dynamic>>> _pendingRequests = {};
  final Map<String, StreamController<Map<String, dynamic>>> _topicControllers =
      {};
  final Map<String, StreamController<Object?>> _streamControllers = {};

  WebSocketRealtimeTransport(
    this._uri, {
    WebSocketConnection Function(Uri)? connectionFactory,
    Uuid? uuid,
  })  : _connectionFactory = connectionFactory ??
            ((uri) => _WebSocketChannelAdapter(WebSocketChannel.connect(uri))),
        _uuid = uuid ?? const Uuid();

  @override
  Stream<RealtimeConnectionState> get connectionState {
    return Stream<RealtimeConnectionState>.multi((controller) {
      final sub = _connectionStateController.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.add(_state);
      controller.onCancel = sub.cancel;
    });
  }

  @override
  Future<void> connect() async {
    if (_state == RealtimeConnectionState.connected ||
        _state == RealtimeConnectionState.connecting) {
      return;
    }
    _updateState(RealtimeConnectionState.connecting);
    final conn = _connectionFactory(_uri);
    await conn.ready;
    _connection = conn;
    _incoming = conn.stream.listen(
      _handleIncoming,
      onError: (_) => _teardown(),
      onDone: _teardown,
    );
    _updateState(RealtimeConnectionState.connected);
  }

  @override
  Future<void> disconnect() async {
    await _incoming?.cancel();
    await _connection?.close();
    _teardown();
  }

  @override
  Future<Map<String, dynamic>> request(
    String type,
    Map<String, dynamic> payload,
  ) async {
    _ensureConnected();
    final requestId = _uuid.v4();
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[requestId] = completer;
    _connection!.send(jsonEncode({
      'type': type,
      'requestId': requestId,
      'payload': payload,
    }));
    return completer.future;
  }

  @override
  Future<void> publish(String topic, Map<String, dynamic> payload) async {
    _ensureConnected();
    _connection!.send(jsonEncode({'topic': topic, 'payload': payload}));
  }

  @override
  Stream<Map<String, dynamic>> subscribe(String topic) {
    final controller = _topicControllers.putIfAbsent(
      topic,
      () => StreamController<Map<String, dynamic>>.broadcast(),
    );
    return controller.stream;
  }

  @override
  Stream<Object?> subscribeStream({
    required String repoName,
    required String method,
    required Map<String, dynamic> args,
  }) {
    final streamId = _uuid.v4();
    late final StreamController<Object?> controller;
    controller = StreamController<Object?>.broadcast(
      onCancel: () async {
        if (_streamControllers.remove(streamId) == null) return;
        if (_state != RealtimeConnectionState.connected) return;
        try {
          await request('stream-unsubscribe', {'streamId': streamId});
        } catch (_) {
          // Connection might be in tear-down; nothing to do.
        }
      },
    );
    _streamControllers[streamId] = controller;

    unawaited(() async {
      try {
        await request('stream-subscribe', {
          'streamId': streamId,
          'repoName': repoName,
          'method': method,
          'args': args,
        });
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
          await controller.close();
        }
        _streamControllers.remove(streamId);
      }
    }());

    return controller.stream;
  }

  void _handleIncoming(dynamic raw) {
    if (raw is! String) return;
    final Map<String, dynamic> msg;
    try {
      msg = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final requestId = msg['requestId'] as String?;
    if (requestId != null) {
      final completer = _pendingRequests.remove(requestId);
      if (completer == null) return;
      final success = msg['success'] as bool? ?? false;
      if (success) {
        completer.complete((msg['data'] as Map<String, dynamic>?) ?? const {});
      } else {
        completer.completeError(
          StateError((msg['error'] as String?) ?? 'Unknown server error'),
        );
      }
      return;
    }

    final type = msg['type'] as String?;
    if (type == 'stream-event' ||
        type == 'stream-error' ||
        type == 'stream-done') {
      final payload = (msg['payload'] as Map<String, dynamic>?) ?? const {};
      final streamId = payload['streamId'] as String?;
      if (streamId == null) return;
      final controller = _streamControllers[streamId];
      if (controller == null) return;
      switch (type) {
        case 'stream-event':
          controller.add(payload['data']);
        case 'stream-error':
          controller.addError(StateError(
              (payload['message'] as String?) ?? 'Stream error'));
        case 'stream-done':
          unawaited(controller.close());
          _streamControllers.remove(streamId);
      }
      return;
    }

    final topic = msg['topic'] as String?;
    if (topic != null) {
      final payload = (msg['payload'] as Map<String, dynamic>?) ?? const {};
      _topicControllers[topic]?.add(payload);
    }
  }

  void _ensureConnected() {
    if (_state != RealtimeConnectionState.connected || _connection == null) {
      throw StateError('Transport is not connected');
    }
  }

  void _updateState(RealtimeConnectionState state) {
    _state = state;
    _connectionStateController.add(state);
  }

  void _teardown() {
    _connection = null;
    _incoming = null;
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('Connection closed'));
      }
    }
    _pendingRequests.clear();
    for (final controller in _streamControllers.values) {
      if (!controller.isClosed) {
        controller.addError(StateError('Connection closed'));
        unawaited(controller.close());
      }
    }
    _streamControllers.clear();
    if (_state != RealtimeConnectionState.disconnected) {
      _updateState(RealtimeConnectionState.disconnected);
    }
  }
}
