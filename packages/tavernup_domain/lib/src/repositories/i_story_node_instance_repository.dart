import '../models/story_node_instance.dart';

/// Repository interface for managing story node instances.
///
/// An instance is created when a game master opens a story node
/// during a session. It holds the group-specific play state.
///
/// Implementations:
/// - `SupabaseStoryNodeInstanceRepository`: persists to Supabase
/// - `MockStoryNodeInstanceRepository`: in-memory implementation for testing
abstract interface class IStoryNodeInstanceRepository {
  /// Returns the instance with [id], or null if not found.
  Future<StoryNodeInstance?> getById(String id);

  /// Returns all instances for [templateId].
  Future<List<StoryNodeInstance>> getForTemplate(String templateId);

  /// Returns or creates an instance for [templateId].
  ///
  /// If an instance for this template already exists, it is returned.
  /// Otherwise a new one is created. This reflects the game master
  /// opening a story node during a session.
  Future<StoryNodeInstance> getOrCreate(String templateId);

  /// Updates the status of the instance with [id].
  Future<void> updateStatus(String id, StoryNodeStatus status);

  /// Permanently deletes the instance with [id].
  Future<void> delete(String id);
}
