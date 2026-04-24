import 'dart:async';

import '../realtime/i_realtime_transport.dart';
import '../realtime/realtime_connection_state.dart';

/// In-memory mock implementation of [IRealtimeTransport].
///
/// Intended for use in tests. Exposes test-only methods to simulate
/// server-initiated pushes ([simulatePush]) and to script responses to
/// [request] calls ([respondTo], [respondWithError]).
class MockRealtimeTransport implements IRealtimeTransport {
  final _stateController =
      StreamController<RealtimeConnectionState>.broadcast();
  final Map<String, StreamController<Map<String, dynamic>>> _topicControllers =
      {};
  final List<_SentRequest> _sentRequests = [];
  final List<_Published> _publishedMessages = [];

  var _state = RealtimeConnectionState.disconnected;

  /// Recorded requests in the order they were sent.
  List<_SentRequest> get sentRequests => List.unmodifiable(_sentRequests);

  /// Recorded publish() calls in the order they happened.
  List<_Published> get publishedMessages =>
      List.unmodifiable(_publishedMessages);

  @override
  Stream<RealtimeConnectionState> get connectionState {
    return Stream<RealtimeConnectionState>.multi((controller) {
      final sub = _stateController.stream.listen(
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
    if (_state == RealtimeConnectionState.connected) return;
    _state = RealtimeConnectionState.connected;
    _stateController.add(_state);
  }

  @override
  Future<void> disconnect() async {
    _state = RealtimeConnectionState.disconnected;
    _stateController.add(_state);
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
  Future<void> publish(String topic, Map<String, dynamic> payload) async {
    _publishedMessages.add(_Published(topic, payload));
  }

  @override
  Future<Map<String, dynamic>> request(
    String type,
    Map<String, dynamic> payload,
  ) {
    final completer = Completer<Map<String, dynamic>>();
    _sentRequests.add(_SentRequest(type, payload, completer));
    return completer.future;
  }

  /// Resolves the pending request matching [type] with [response] data.
  ///
  /// Throws if no matching pending request exists.
  void respondTo(String type, [Map<String, dynamic> response = const {}]) {
    final pending = _sentRequests.firstWhere(
      (r) => r.type == type && !r.completer.isCompleted,
      orElse: () => throw StateError('No pending request of type "$type"'),
    );
    pending.completer.complete(response);
  }

  /// Rejects the pending request matching [type] with [error].
  void respondWithError(String type, Object error) {
    final pending = _sentRequests.firstWhere(
      (r) => r.type == type && !r.completer.isCompleted,
      orElse: () => throw StateError('No pending request of type "$type"'),
    );
    pending.completer.completeError(error);
  }

  /// Simulates a server-initiated push to [topic] with [payload].
  void simulatePush(String topic, Map<String, dynamic> payload) {
    _topicControllers[topic]?.add(payload);
  }

  /// Releases resources. Call in [tearDown] after tests.
  Future<void> dispose() async {
    await _stateController.close();
    for (final c in _topicControllers.values) {
      await c.close();
    }
  }
}

class _SentRequest {
  final String type;
  final Map<String, dynamic> payload;
  final Completer<Map<String, dynamic>> completer;
  _SentRequest(this.type, this.payload, this.completer);
}

class _Published {
  final String topic;
  final Map<String, dynamic> payload;
  _Published(this.topic, this.payload);
}
