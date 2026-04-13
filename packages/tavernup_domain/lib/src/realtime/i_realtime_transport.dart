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
