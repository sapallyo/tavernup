import 'package:tavernup_domain/tavernup_domain.dart';

class RemoteCharacterRepository implements ICharacterRepository {
  final IRealtimeTransport _transport;

  RemoteCharacterRepository(this._transport);

  @override
  Future<List<Character>> getOwned(String ownerId) async {
    final result = (await _transport.request(
        'repo.character.getOwned', {'ownerId': ownerId}))['result'] as List;
    return result.map((m) => Character.fromJson(m as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Character>> getVisible(String userId) async {
    final result = (await _transport.request(
        'repo.character.getVisible', {'userId': userId}))['result'] as List;
    return result.map((m) => Character.fromJson(m as Map<String, dynamic>)).toList();
  }

  @override
  Future<Character?> getById(String id) async {
    final result =
        (await _transport.request('repo.character.getById', {'id': id}))['result'];
    return result == null
        ? null
        : Character.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<void> save(Character character) async {
    await _transport
        .request('repo.character.save', {'character': character.toJson()});
  }

  @override
  Future<void> delete(String id) async {
    await _transport.request('repo.character.delete', {'id': id});
  }

  @override
  Future<void> grantVisibility(String characterId, String userId) async {
    await _transport.request('repo.character.grantVisibility',
        {'characterId': characterId, 'userId': userId});
  }

  @override
  Future<void> revokeVisibility(String characterId, String userId) async {
    await _transport.request('repo.character.revokeVisibility',
        {'characterId': characterId, 'userId': userId});
  }

  @override
  Stream<List<Character>> watchOwned(String ownerId) {
    return _transport
        .subscribeStream(
          repoName: 'character',
          method: 'watchOwned',
          args: {'ownerId': ownerId},
        )
        .map((event) => (event as List)
            .map((m) => Character.fromJson(m as Map<String, dynamic>))
            .toList());
  }
}
