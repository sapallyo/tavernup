import '../models/game_group_membership.dart';
import '../models/invitation.dart';
import '../repositories/i_invitation_repository.dart';

/// In-memory implementation of [IInvitationRepository] for testing.
class MockInvitationRepository implements IInvitationRepository {
  final Map<String, Invitation> _store = {};

  void seed(List<Invitation> invitations) {
    for (final i in invitations) {
      _store[i.id] = i;
    }
  }

  @override
  String get entityType => 'invitation';

  @override
  Future<String> create(Map<String, dynamic> data) async {
    final inv = await createInvitation(
      data['gameGroupId'] as String,
      GameGroupRole.fromString(data['role'] as String? ?? 'player'),
      data['invitedUserId'] as String,
    );
    return inv.id;
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    final invitation = _store[id];
    if (invitation == null) return;
    final updated = Invitation.fromJson({
      ...invitation.toJson(),
      'id': invitation.id,
      'expires_at': invitation.expiresAt.toIso8601String(),
      'created_at': invitation.createdAt.toIso8601String(),
      ...data,
    });
    _store[id] = updated;
  }

  @override
  Future<void> delete(String id) async => _store.remove(id);

  @override
  Future<Invitation> createInvitation(
    String gameGroupId,
    GameGroupRole role,
    String invitedUserId,
  ) async {
    final invitation = Invitation(
      id: 'inv-${_store.length + 1}',
      gameGroupId: gameGroupId,
      role: role,
      createdBy: 'mock-user',
      invitedUserId: invitedUserId,
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      createdAt: DateTime.now(),
    );
    _store[invitation.id] = invitation;
    return invitation;
  }

  @override
  Future<Invitation?> getById(String id) async => _store[id];

  @override
  Future<List<Invitation>> getForUser(String userId) async =>
      _store.values.where((i) => i.invitedUserId == userId).toList();

  @override
  Future<List<Invitation>> getForGameGroup(String gameGroupId) async =>
      _store.values.where((i) => i.gameGroupId == gameGroupId).toList();
}
