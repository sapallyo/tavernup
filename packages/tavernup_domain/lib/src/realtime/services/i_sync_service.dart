/// Service interface for watching live changes to domain entities.
///
/// Provides a generic mechanism for subscribing to realtime updates
/// of any entity or collection, independent of the underlying transport
/// or storage technology.
///
/// The application's domain layer defines what to watch; this interface
/// defines how to watch it. Implementations translate the subscription
/// into the appropriate transport call (Supabase Realtime, WebSocket, etc.).
///
/// Implementations:
/// - `SupabaseSyncService`: uses Supabase Realtime row-level changes
/// - `MockSyncService`: in-memory implementation for testing
abstract interface class ISyncService {
  /// Watches a single entity by its ID.
  ///
  /// Emits the latest version of the entity whenever it changes remotely.
  /// The first emission contains the current state at subscription time.
  ///
  /// [fromJson] converts the raw payload into the domain type [T].
  /// The [collection] identifies the data source (e.g. a table name).
  ///
  /// The stream completes if the entity is deleted.
  Stream<T> watchById<T>(
    String collection,
    String id, {
    required T Function(Map<String, dynamic>) fromJson,
  });

  /// Watches a collection of entities filtered by a single field value.
  ///
  /// Emits the full current list whenever any matching entity changes.
  /// Clients should replace their local list on each emission.
  ///
  /// [fromJson] converts each raw payload item into the domain type [T].
  ///
  /// Example — watch all characters in a group:
  /// ```dart
  /// syncService.watchWhere<Character>(
  ///   'characters',
  ///   field: 'group_id',
  ///   value: groupId,
  ///   fromJson: Character.fromJson,
  /// );
  /// ```
  Stream<List<T>> watchWhere<T>(
    String collection, {
    required String field,
    required String value,
    required T Function(Map<String, dynamic>) fromJson,
  });
}
