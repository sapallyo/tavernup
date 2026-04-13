import '../models/game_group.dart';
import '../models/game_group_membership.dart';
import '../models/user.dart';
import '../repositories/i_game_group_repository.dart';

/// In-memory implementation of [IGameGroupRepository] for testing.
class MockGameGroupRepository implements IGameGroupRepository {
  final Map<String, GameGroup> _groups = {};
  final Map<String, GameGroupMembership> _memberships = {};

  void seed(List<GameGroup> groups, {List<GameGroupMembership>? memberships}) {
    for (final g in groups) {
      _groups[g.id] = g;
    }
    for (final m in memberships ?? []) {
      _memberships[m.id] = m;
    }
  }

  // ── IEntityRepository ────────────────────────────────────────────────────────

  @override
  String get entityType => 'membership';

  /// Creates a membership from [data].
  ///
  /// Expected keys: `gameGroupId`, `userId`, `role`.
  /// Returns a composite ID in the form `gameGroupId:userId`.
  @override
  Future<String> create(Map<String, dynamic> data) async {
    final gameGroupId = data['gameGroupId'] as String;
    final userId = data['userId'] as String;
    final role = GameGroupRole.fromString(data['role'] as String? ?? 'player');
    await addMember(gameGroupId, userId, role);
    return '$gameGroupId:$userId';
  }

  /// Not supported — memberships cannot be updated.
  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    throw UnimplementedError('Membership update is not supported.');
  }

  /// Removes a membership identified by composite [id] (`gameGroupId:userId`).
  @override
  Future<void> delete(String id) async {
    final parts = id.split(':');
    if (parts.length != 2) {
      throw ArgumentError('Invalid membership id format: $id');
    }
    await removeMember(parts[0], parts[1], GameGroupRole.player);
  }

  // ── IGameGroupRepository ─────────────────────────────────────────────────────

  @override
  Future<List<GameGroup>> getAll(String userId) async {
    final groupIds = _memberships.values
        .where((m) => m.userId == userId)
        .map((m) => m.gameGroupId)
        .toSet();
    return _groups.values.where((g) => groupIds.contains(g.id)).toList();
  }

  @override
  Future<GameGroup?> getById(String id) async => _groups[id];

  @override
  Future<GameGroup> createGameGroup(
      String name, String? description, String ruleset) async {
    final group = GameGroup(
      id: 'group-${_groups.length + 1}',
      name: name,
      description: description,
      createdBy: 'mock-user',
      ruleset: ruleset,
      createdAt: DateTime.now(),
    );
    _groups[group.id] = group;
    return group;
  }

  @override
  Future<void> addMember(
      String gameGroupId, String userId, GameGroupRole role) async {
    final id = 'membership-${_memberships.length + 1}';
    _memberships[id] = GameGroupMembership(
      id: id,
      gameGroupId: gameGroupId,
      userId: userId,
      role: role,
      joinedAt: DateTime.now(),
    );
  }

  @override
  Future<void> removeMember(
      String gameGroupId, String userId, GameGroupRole role) async {
    _memberships.removeWhere(
      (_, m) => m.gameGroupId == gameGroupId && m.userId == userId,
    );
  }

  @override
  Future<List<GameGroupMembership>> getMembers(String gameGroupId) async =>
      _memberships.values.where((m) => m.gameGroupId == gameGroupId).toList();

  @override
  Future<List<(GameGroupMembership, User?)>> getMembersWithProfiles(
      String gameGroupId) async {
    final members = await getMembers(gameGroupId);
    return members.map((m) => (m, null as User?)).toList();
  }

  @override
  Future<List<GameGroupRole>> getRolesForUser(
      String gameGroupId, String userId) async {
    return _memberships.values
        .where((m) => m.gameGroupId == gameGroupId && m.userId == userId)
        .map((m) => m.role)
        .toList();
  }

  @override
  Stream<List<GameGroup>> watchAll(String userId) =>
      Stream.value(_groups.values.toList());
}
