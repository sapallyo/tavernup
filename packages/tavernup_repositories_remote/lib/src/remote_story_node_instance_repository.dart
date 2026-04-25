import 'package:tavernup_domain/tavernup_domain.dart';

class RemoteStoryNodeInstanceRepository
    implements IStoryNodeInstanceRepository {
  final IRealtimeTransport _transport;

  RemoteStoryNodeInstanceRepository(this._transport);

  @override
  Future<StoryNodeInstance?> getById(String id) async {
    final result = (await _transport
        .request('repo.storyNodeInstance.getById', {'id': id}))['result'];
    return result == null
        ? null
        : StoryNodeInstance.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<List<StoryNodeInstance>> getForTemplate(String templateId) async {
    final result = (await _transport.request(
        'repo.storyNodeInstance.getForTemplate',
        {'templateId': templateId}))['result'] as List;
    return result
        .map((m) => StoryNodeInstance.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<StoryNodeInstance> getOrCreate(String templateId) async {
    final result = (await _transport.request(
        'repo.storyNodeInstance.getOrCreate',
        {'templateId': templateId}))['result'];
    return StoryNodeInstance.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<void> updateStatus(String id, StoryNodeStatus status) async {
    await _transport.request('repo.storyNodeInstance.updateStatus',
        {'id': id, 'status': status.name});
  }

  @override
  Future<void> delete(String id) async {
    await _transport.request('repo.storyNodeInstance.delete', {'id': id});
  }
}
