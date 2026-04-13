/// Interface for a repository that supports generic CRUD operations
/// on a specific entity type.
///
/// Used by [EntityWorker] to perform create, update, and delete
/// operations without knowing the concrete entity type.
///
/// Each implementation is responsible for mapping generic
/// [Map<String, dynamic>] data to and from its typed domain model.
///
/// The [entityType] string must match the value used in the BPMN
/// extension property `entityType` on the service task.
abstract interface class IEntityRepository {
  /// The entity type identifier this repository handles.
  ///
  /// Must be unique across all registered repositories.
  /// Examples: `invitation`, `membership`, `character`.
  String get entityType;

  /// Creates a new entity from [data] and returns its ID.
  Future<String> create(Map<String, dynamic> data);

  /// Updates an existing entity identified by [id].
  ///
  /// [data] contains only the fields to update.
  Future<void> update(String id, Map<String, dynamic> data);

  /// Permanently deletes the entity with [id].
  Future<void> delete(String id);
}
