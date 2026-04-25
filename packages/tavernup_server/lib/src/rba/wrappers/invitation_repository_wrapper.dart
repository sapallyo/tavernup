import 'package:tavernup_domain/tavernup_domain.dart';

import '../principal.dart';

/// Authorizing wrapper around a raw [IInvitationRepository].
///
/// Currently pass-through: every call delegates to the raw repository
/// regardless of the principal. Filter and projection logic per
/// principal will be added when the role catalog is filled in.
class InvitationRepositoryWrapper implements IInvitationRepository {
  final IInvitationRepository _raw;
  // ignore: unused_field
  final Principal _principal;

  InvitationRepositoryWrapper(this._raw, this._principal);

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
  Future<Invitation> createInvitation(
    String gameGroupId,
    GameGroupRole role,
    String invitedUserId,
  ) =>
      _raw.createInvitation(gameGroupId, role, invitedUserId);

  @override
  Future<Invitation?> getById(String id) => _raw.getById(id);

  @override
  Future<List<Invitation>> getForUser(String userId) =>
      _raw.getForUser(userId);

  @override
  Future<List<Invitation>> getForGameGroup(String gameGroupId) =>
      _raw.getForGameGroup(gameGroupId);
}
