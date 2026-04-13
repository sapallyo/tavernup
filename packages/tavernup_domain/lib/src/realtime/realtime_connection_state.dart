/// Represents the current state of a realtime transport connection.
enum RealtimeConnectionState {
  /// No active connection. Either not yet connected or explicitly disconnected.
  disconnected,

  /// Connection attempt is in progress.
  connecting,

  /// Connection is established and ready to send and receive messages.
  connected,

  /// Connection was lost and is being re-established automatically.
  reconnecting,
}
