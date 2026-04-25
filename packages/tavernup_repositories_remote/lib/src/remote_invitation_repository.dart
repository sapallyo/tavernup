import 'package:tavernup_domain/tavernup_domain.dart';

class RemoteInvitationRepository implements IInvitationRepository {
  final IRealtimeTransport _transport;

  RemoteInvitationRepository(this._transport);

  @override
  String get entityType => 'invitation';

  @override
  Future<String> create(Map<String, dynamic> data) async {
    final result = (await _transport
        .request('repo.invitation.create', {'data': data}))['result'];
    return result as String;
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    await _transport
        .request('repo.invitation.update', {'id': id, 'data': data});
  }

  @override
  Future<void> delete(String id) async {
    await _transport.request('repo.invitation.delete', {'id': id});
  }

  @override
  Future<Invitation> createInvitation(
    String gameGroupId,
    GameGroupRole role,
    String invitedUserId,
  ) async {
    final result =
        (await _transport.request('repo.invitation.createInvitation', {
      'gameGroupId': gameGroupId,
      'role': role.name,
      'invitedUserId': invitedUserId,
    }))['result'];
    return Invitation.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<Invitation?> getById(String id) async {
    final result =
        (await _transport.request('repo.invitation.getById', {'id': id}))['result'];
    return result == null
        ? null
        : Invitation.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<List<Invitation>> getForUser(String userId) async {
    final result = (await _transport.request(
        'repo.invitation.getForUser', {'userId': userId}))['result'] as List;
    return result
        .map((m) => Invitation.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Invitation>> getForGameGroup(String gameGroupId) async {
    final result = (await _transport.request(
        'repo.invitation.getForGameGroup',
        {'gameGroupId': gameGroupId}))['result'] as List;
    return result
        .map((m) => Invitation.fromJson(m as Map<String, dynamic>))
        .toList();
  }
}
