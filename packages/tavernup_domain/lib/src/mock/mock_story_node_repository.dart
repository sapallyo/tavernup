import '../models/story_node.dart';
import '../repositories/i_story_node_repository.dart';

/// In-memory implementation of [IStoryNodeRepository] for testing.
class MockStoryNodeRepository implements IStoryNodeRepository {
  final Map<String, StoryNode> _store = {};

  void seed(List<StoryNode> nodes) {
    for (final n in nodes) {
      _store[n.id] = n;
    }
  }

  @override
  Future<List<StoryNode>> getRoots(String userId) async =>
      _store.values.where((n) => n.isRoot && n.createdBy == userId).toList();

  @override
  Future<List<StoryNode>> getChildren(String parentId) async =>
      _store.values.where((n) => n.parentId == parentId).toList();

  @override
  Future<StoryNode?> getById(String id) async => _store[id];

  @override
  Future<StoryNode> create({
    required String title,
    String? description,
    String? imageUrl,
    String? systemKey,
    String? parentId,
  }) async {
    final node = StoryNode(
      id: 'node-${_store.length + 1}',
      title: title,
      description: description,
      imageUrl: imageUrl,
      systemKey: systemKey,
      parentId: parentId,
      createdBy: 'mock-user',
      createdAt: DateTime.now(),
    );
    _store[node.id] = node;
    return node;
  }

  @override
  Future<void> save(StoryNode node) async => _store[node.id] = node;

  @override
  Future<void> delete(String id) async => _store.remove(id);

  @override
  Stream<List<StoryNode>> watchChildren(String parentId) => Stream.value(
        _store.values.where((n) => n.parentId == parentId).toList(),
      );
}
