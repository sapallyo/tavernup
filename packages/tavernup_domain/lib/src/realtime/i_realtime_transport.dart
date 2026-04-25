import 'realtime_connection_state.dart';

/// Low-level interface for bidirectional realtime message transport.
///
/// This is the foundation of the realtime layer. It knows nothing about
/// the application's domain — it only moves raw payloads between topics.
///
/// Higher-level services ([IProcessEventService], [ISyncService]) build
/// on top of this interface and translate raw payloads into domain objects.
///
/// Implementations:
/// - `SupabaseRealtimeTransport`: uses Supabase Realtime channels
/// - `WebSocketTransport`: uses a direct WebSocket connection to the worker
/// - `MockRealtimeTransport`: in-memory implementation for testing
abstract interface class IRealtimeTransport {
  /// The current connection state as a continuous stream.
  ///
  /// Always emits the current state immediately upon subscription,
  /// followed by any subsequent state changes.
  Stream<RealtimeConnectionState> get connectionState;

  /// Subscribes to a topic and returns a stream of raw payloads.
  ///
  /// [topic] is an arbitrary string identifier. The naming convention
  /// is defined by the services that use this transport, for example:
  /// `user_tasks:user-123` or `characters:group-456`.
  ///
  /// The stream stays open until [disconnect] is called or the
  /// subscription is cancelled by the subscriber.
  ///
  /// Multiple subscriptions to the same topic are allowed and each
  /// receives its own independent stream.
  Stream<Map<String, dynamic>> subscribe(String topic);

  /// Sends a payload to a topic.
  ///
  /// Returns when the send is acknowledged by the transport layer.
  /// Does not guarantee delivery to any specific subscriber.
  ///
  /// Throws if the transport is not connected.
  Future<void> publish(String topic, Map<String, dynamic> payload);

  /// Sends a request and returns the correlated response payload.
  ///
  /// Implements the requestId pattern for synchronous request/response
  /// semantics over an asynchronous transport. The implementation
  /// assigns a unique requestId, sends the message, and completes the
  /// returned future when the matching response arrives.
  ///
  /// [type] identifies the server-side handler (e.g. `validate-user`,
  /// `complete-task`). The resulting map is the `data` field of a
  /// successful response.
  ///
  /// Throws with the server-provided error message if the server
  /// responds with `success: false`, or if the transport is not
  /// connected / the connection drops before a response arrives.
  Future<Map<String, dynamic>> request(
    String type,
    Map<String, dynamic> payload,
  );

  /// Subscribes to a server-side stream method via the stream-subscribe
  /// protocol introduced in Phase 5. The implementation sends a
  /// `stream-subscribe` frame, routes the resulting `stream-event` /
  /// `stream-error` / `stream-done` frames back to the returned stream,
  /// and sends a `stream-unsubscribe` frame on cancellation.
  ///
  /// [repoName] / [method] / [args] match the server-side stream
  /// resolver — see `SubscriptionManager`.
  ///
  /// Each emitted event is the raw `data` payload from the server (a
  /// JSON-encodable value). Higher-level callers map it to domain
  /// objects.
  Stream<Object?> subscribeStream({
    required String repoName,
    required String method,
    required Map<String, dynamic> args,
  });

  /// Opens the connection.
  ///
  /// Must be called before [subscribe] or [publish].
  /// Has no effect if already connected.
  Future<void> connect();

  /// Closes the connection and releases all resources.
  ///
  /// All active subscriptions are terminated.
  /// After calling this, [connect] must be called again to resume.
  Future<void> disconnect();
}
