import 'package:tavernup_domain/tavernup_domain.dart';

class RemoteGameGroupRepository implements IGameGroupRepository {
  final IRealtimeTransport _transport;

  RemoteGameGroupRepository(this._transport);

  @override
  String get entityType => 'membership';

  @override
  Future<String> create(Map<String, dynamic> data) async {
    final result = (await _transport
        .request('repo.gameGroup.create', {'data': data}))['result'];
    return result as String;
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    await _transport
        .request('repo.gameGroup.update', {'id': id, 'data': data});
  }

  @override
  Future<void> delete(String id) async {
    await _transport.request('repo.gameGroup.delete', {'id': id});
  }

  @override
  Future<List<GameGroup>> getAll(String userId) async {
    final result = (await _transport
        .request('repo.gameGroup.getAll', {'userId': userId}))['result'] as List;
    return result.map((m) => GameGroup.fromJson(m as Map<String, dynamic>)).toList();
  }

  @override
  Future<GameGroup?> getById(String id) async {
    final result =
        (await _transport.request('repo.gameGroup.getById', {'id': id}))['result'];
    return result == null
        ? null
        : GameGroup.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<GameGroup> createGameGroup(
      String name, String? description, String ruleset) async {
    final result = (await _transport.request('repo.gameGroup.createGameGroup', {
      'name': name,
      if (description != null) 'description': description,
      'ruleset': ruleset,
    }))['result'];
    return GameGroup.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<void> addMember(
      String gameGroupId, String userId, GameGroupRole role) async {
    await _transport.request('repo.gameGroup.addMember', {
      'gameGroupId': gameGroupId,
      'userId': userId,
      'role': role.name,
    });
  }

  @override
  Future<void> removeMember(
      String gameGroupId, String userId, GameGroupRole role) async {
    await _transport.request('repo.gameGroup.removeMember', {
      'gameGroupId': gameGroupId,
      'userId': userId,
      'role': role.name,
    });
  }

  @override
  Future<List<GameGroupMembership>> getMembers(String gameGroupId) async {
    final result = (await _transport.request(
        'repo.gameGroup.getMembers',
        {'gameGroupId': gameGroupId}))['result'] as List;
    return result
        .map((m) => GameGroupMembership.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<(GameGroupMembership, User?)>> getMembersWithProfiles(
      String gameGroupId) async {
    final result = (await _transport.request(
            'repo.gameGroup.getMembersWithProfiles',
            {'gameGroupId': gameGroupId}))['result']
        as List;
    return result.map((entry) {
      final map = entry as Map<String, dynamic>;
      return (
        GameGroupMembership.fromJson(map['membership'] as Map<String, dynamic>),
        map['user'] == null
            ? null
            : User.fromJson(map['user'] as Map<String, dynamic>),
      );
    }).toList();
  }

  @override
  Future<List<GameGroupRole>> getRolesForUser(
      String gameGroupId, String userId) async {
    final result = (await _transport.request(
        'repo.gameGroup.getRolesForUser',
        {'gameGroupId': gameGroupId, 'userId': userId}))['result'] as List;
    return result
        .map((name) => GameGroupRole.values.byName(name as String))
        .toList();
  }

  @override
  Stream<List<GameGroup>> watchAll(String userId) {
    return _transport
        .subscribeStream(
          repoName: 'gameGroup',
          method: 'watchAll',
          args: {'userId': userId},
        )
        .map((event) => (event as List)
            .map((m) => GameGroup.fromJson(m as Map<String, dynamic>))
            .toList());
  }
}
