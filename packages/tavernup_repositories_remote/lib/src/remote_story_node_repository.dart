import 'package:tavernup_domain/tavernup_domain.dart';

class RemoteStoryNodeRepository implements IStoryNodeRepository {
  final IRealtimeTransport _transport;

  RemoteStoryNodeRepository(this._transport);

  @override
  Future<List<StoryNode>> getRoots(String userId) async {
    final result = (await _transport
        .request('repo.storyNode.getRoots', {'userId': userId}))['result'] as List;
    return result
        .map((m) => StoryNode.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<StoryNode>> getChildren(String parentId) async {
    final result = (await _transport.request(
        'repo.storyNode.getChildren', {'parentId': parentId}))['result'] as List;
    return result
        .map((m) => StoryNode.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<StoryNode?> getById(String id) async {
    final result =
        (await _transport.request('repo.storyNode.getById', {'id': id}))['result'];
    return result == null
        ? null
        : StoryNode.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<StoryNode> create({
    required String title,
    String? description,
    String? imageUrl,
    String? systemKey,
    String? parentId,
  }) async {
    final result = (await _transport.request('repo.storyNode.create', {
      'title': title,
      if (description != null) 'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (systemKey != null) 'systemKey': systemKey,
      if (parentId != null) 'parentId': parentId,
    }))['result'];
    return StoryNode.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<void> save(StoryNode node) async {
    await _transport.request('repo.storyNode.save', {'node': node.toJson()});
  }

  @override
  Future<void> delete(String id) async {
    await _transport.request('repo.storyNode.delete', {'id': id});
  }

  @override
  Stream<List<StoryNode>> watchChildren(String parentId) {
    return _transport
        .subscribeStream(
          repoName: 'storyNode',
          method: 'watchChildren',
          args: {'parentId': parentId},
        )
        .map((event) => (event as List)
            .map((m) => StoryNode.fromJson(m as Map<String, dynamic>))
            .toList());
  }
}
