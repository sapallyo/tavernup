import '../models/game_group_membership.dart';
import '../models/invitation.dart';

/// Repository interface for managing invitations.
///
/// Invitations are created by group admins or game masters and
/// sent to a specific user. Once accepted, a [GameGroupMembership]
/// is created and the invitation is no longer active.
///
/// Implementations:
/// - `SupabaseInvitationRepository`: persists to Supabase
/// - `MockInvitationRepository`: in-memory implementation for testing
abstract interface class IInvitationRepository {
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

  /// Updates individual fields of the invitation with [id].
  ///
  /// [data] is a map of field names to new values.
  /// Used to update status, expiry, or other mutable fields
  /// without replacing the entire invitation.
  Future<void> updateFields(String id, Map<String, dynamic> data);

  /// Permanently deletes the invitation with [id].
  Future<void> delete(String id);
}
