import '../models/story_node.dart';

/// Repository interface for managing story node templates.
///
/// Story nodes form a recursive tree structure. A root node
/// represents a campaign, its children adventures, and so on.
///
/// Implementations:
/// - `SupabaseStoryNodeRepository`: persists to Supabase
/// - `MockStoryNodeRepository`: in-memory implementation for testing
abstract interface class IStoryNodeRepository {
  /// Returns all root nodes (campaigns) created by [userId].
  Future<List<StoryNode>> getRoots(String userId);

  /// Returns all direct children of [parentId].
  Future<List<StoryNode>> getChildren(String parentId);

  /// Returns the node with [id], or null if not found.
  Future<StoryNode?> getById(String id);

  /// Creates a new story node.
  ///
  /// If [parentId] is null, the node is a root node.
  Future<StoryNode> create({
    required String title,
    String? description,
    String? imageUrl,
    String? systemKey,
    String? parentId,
  });

  /// Saves changes to an existing node.
  Future<void> save(StoryNode node);

  /// Permanently deletes the node with [id].
  ///
  /// Does not automatically delete child nodes or existing
  /// [StoryNodeInstance]s that reference this node.
  Future<void> delete(String id);

  /// Returns a stream of direct children of [parentId].
  ///
  /// Emits the current list immediately, then re-emits on changes.
  Stream<List<StoryNode>> watchChildren(String parentId);
}
