import 'package:tavernup_domain/tavernup_domain.dart';

class RemoteSessionRepository implements ISessionRepository {
  final IRealtimeTransport _transport;

  RemoteSessionRepository(this._transport);

  @override
  Future<Session?> getById(String id) async {
    final result =
        (await _transport.request('repo.session.getById', {'id': id}))['result'];
    return result == null
        ? null
        : Session.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<List<Session>> getByIds(List<String> sessionIds) async {
    final result = (await _transport.request(
        'repo.session.getByIds', {'sessionIds': sessionIds}))['result'] as List;
    return result
        .map((m) => Session.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Session> create() async {
    final result =
        (await _transport.request('repo.session.create', {}))['result'];
    return Session.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<void> addInstance(String sessionId, String instanceId) async {
    await _transport.request('repo.session.addInstance',
        {'sessionId': sessionId, 'instanceId': instanceId});
  }

  @override
  Future<void> removeInstance(String sessionId, String instanceId) async {
    await _transport.request('repo.session.removeInstance',
        {'sessionId': sessionId, 'instanceId': instanceId});
  }

  @override
  Future<void> addParticipant(
      String sessionId, AdventureCharacter participant) async {
    await _transport.request('repo.session.addParticipant',
        {'sessionId': sessionId, 'participant': participant.toJson()});
  }

  @override
  Future<void> removeParticipant(
      String sessionId, String participantId) async {
    await _transport.request('repo.session.removeParticipant',
        {'sessionId': sessionId, 'participantId': participantId});
  }

  @override
  Future<void> delete(String id) async {
    await _transport.request('repo.session.delete', {'id': id});
  }

  @override
  Stream<List<Session>> watchByIds(List<String> sessionIds) {
    return _transport
        .subscribeStream(
          repoName: 'session',
          method: 'watchByIds',
          args: {'sessionIds': sessionIds},
        )
        .map((event) => (event as List)
            .map((m) => Session.fromJson(m as Map<String, dynamic>))
            .toList());
  }
}
