import '../models/story_node_instance.dart';
import '../repositories/i_story_node_instance_repository.dart';

/// In-memory implementation of [IStoryNodeInstanceRepository] for testing.
class MockStoryNodeInstanceRepository implements IStoryNodeInstanceRepository {
  final Map<String, StoryNodeInstance> _store = {};

  void seed(List<StoryNodeInstance> instances) {
    for (final i in instances) {
      _store[i.id] = i;
    }
  }

  @override
  Future<StoryNodeInstance?> getById(String id) async => _store[id];

  @override
  Future<List<StoryNodeInstance>> getForTemplate(String templateId) async =>
      _store.values.where((i) => i.templateId == templateId).toList();

  @override
  Future<StoryNodeInstance> getOrCreate(String templateId) async {
    try {
      return _store.values.firstWhere((i) => i.templateId == templateId);
    } catch (_) {
      final instance = StoryNodeInstance(
        id: 'inst-${_store.length + 1}',
        templateId: templateId,
        createdBy: 'mock-user',
        createdAt: DateTime.now(),
      );
      _store[instance.id] = instance;
      return instance;
    }
  }

  @override
  Future<void> updateStatus(String id, StoryNodeStatus status) async {
    final instance = _store[id];
    if (instance == null) return;
    _store[id] = instance.copyWith(status: status);
  }

  @override
  Future<void> delete(String id) async => _store.remove(id);
}
