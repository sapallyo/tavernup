import '../models/game_group_membership.dart';
import '../models/invitation.dart';
import 'i_entity_repository.dart';

/// Repository interface for managing invitations.
///
/// Extends [IEntityRepository] so that [EntityWorker] can perform
/// generic create, update, and delete operations without knowing
/// the concrete invitation type.
///
/// Implementations:
/// - `SupabaseInvitationRepository`: persists to Supabase
/// - `MockInvitationRepository`: in-memory implementation for testing
abstract interface class IInvitationRepository implements IEntityRepository {
  @override
  String get entityType => 'invitation';

  /// Creates a new pending invitation for [invitedUserId] to join
  /// [gameGroupId] with the given [role].
  Future<Invitation> createInvitation(
    String gameGroupId,
    GameGroupRole role,
    String invitedUserId,
  );

  /// Returns the invitation with [id], or null if not found.
  Future<Invitation?> getById(String id);

  /// Returns all pending invitations for [userId].
  Future<List<Invitation>> getForUser(String userId);

  /// Returns all invitations for [gameGroupId].
  Future<List<Invitation>> getForGameGroup(String gameGroupId);
}
