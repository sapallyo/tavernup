import '../models/game_group.dart';
import '../models/game_group_membership.dart';
import '../models/user.dart';
import 'i_entity_repository.dart';

/// Repository interface for managing game groups and their members.
///
/// Extends [IEntityRepository] to allow [EntityWorker] to manage
/// memberships generically. The [entityType] for this repository
/// is `membership` — create, update and delete operate on memberships,
/// not on game groups themselves.
///
/// Implementations:
/// - `SupabaseGameGroupRepository`: persists to Supabase
/// - `MockGameGroupRepository`: in-memory implementation for testing
abstract interface class IGameGroupRepository implements IEntityRepository {
  @override
  String get entityType => 'membership';

  /// Returns all game groups the given [userId] is a member of.
  Future<List<GameGroup>> getAll(String userId);

  /// Returns the game group with [id], or null if not found.
  Future<GameGroup?> getById(String id);

  /// Creates a new game group owned by the currently authenticated user.
  Future<GameGroup> createGameGroup(
      String name, String? description, String ruleset);

  /// Adds [userId] to [gameGroupId] with the given [role].
  Future<void> addMember(String gameGroupId, String userId, GameGroupRole role);

  /// Removes [userId] from [gameGroupId].
  Future<void> removeMember(
      String gameGroupId, String userId, GameGroupRole role);

  /// Returns all memberships for [gameGroupId].
  Future<List<GameGroupMembership>> getMembers(String gameGroupId);

  /// Returns all memberships for [gameGroupId] paired with their users.
  ///
  /// The user may be null if the user record cannot be found.
  Future<List<(GameGroupMembership, User?)>> getMembersWithProfiles(
      String gameGroupId);

  /// Returns the roles held by [userId] in [gameGroupId].
  Future<List<GameGroupRole>> getRolesForUser(
      String gameGroupId, String userId);

  /// Returns a stream of all game groups [userId] is a member of.
  ///
  /// Emits the current list immediately, then re-emits on changes.
  Stream<List<GameGroup>> watchAll(String userId);
}
