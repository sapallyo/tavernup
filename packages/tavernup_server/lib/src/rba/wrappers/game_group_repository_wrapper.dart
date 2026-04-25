import 'package:tavernup_domain/tavernup_domain.dart';

import '../principal.dart';

/// Authorizing wrapper around a raw [IGameGroupRepository].
///
/// Currently pass-through: every call delegates to the raw repository
/// regardless of the principal. Filter and projection logic per
/// principal will be added when the role catalog is filled in.
class GameGroupRepositoryWrapper implements IGameGroupRepository {
  final IGameGroupRepository _raw;
  // ignore: unused_field
  final Principal _principal;

  GameGroupRepositoryWrapper(this._raw, this._principal);

  @override
  String get entityType => _raw.entityType;

  @override
  Future<String> create(Map<String, dynamic> data) => _raw.create(data);

  @override
  Future<void> update(String id, Map<String, dynamic> data) =>
      _raw.update(id, data);

  @override
  Future<void> delete(String id) => _raw.delete(id);

  @override
  Future<List<GameGroup>> getAll(String userId) => _raw.getAll(userId);

  @override
  Future<GameGroup?> getById(String id) => _raw.getById(id);

  @override
  Future<GameGroup> createGameGroup(
          String name, String? description, String ruleset) =>
      _raw.createGameGroup(name, description, ruleset);

  @override
  Future<void> addMember(
          String gameGroupId, String userId, GameGroupRole role) =>
      _raw.addMember(gameGroupId, userId, role);

  @override
  Future<void> removeMember(
          String gameGroupId, String userId, GameGroupRole role) =>
      _raw.removeMember(gameGroupId, userId, role);

  @override
  Future<List<GameGroupMembership>> getMembers(String gameGroupId) =>
      _raw.getMembers(gameGroupId);

  @override
  Future<List<(GameGroupMembership, User?)>> getMembersWithProfiles(
          String gameGroupId) =>
      _raw.getMembersWithProfiles(gameGroupId);

  @override
  Future<List<GameGroupRole>> getRolesForUser(
          String gameGroupId, String userId) =>
      _raw.getRolesForUser(gameGroupId, userId);

  @override
  Stream<List<GameGroup>> watchAll(String userId) => _raw.watchAll(userId);
}
