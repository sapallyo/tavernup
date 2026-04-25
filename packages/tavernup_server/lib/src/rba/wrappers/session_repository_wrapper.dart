import 'package:tavernup_domain/tavernup_domain.dart';

import '../principal.dart';

/// Authorizing wrapper around a raw [ISessionRepository].
///
/// Currently pass-through: every call delegates to the raw repository
/// regardless of the principal. Filter and projection logic per
/// principal will be added when the role catalog is filled in.
class SessionRepositoryWrapper implements ISessionRepository {
  final ISessionRepository _raw;
  // ignore: unused_field
  final Principal _principal;

  SessionRepositoryWrapper(this._raw, this._principal);

  @override
  Future<Session?> getById(String id) => _raw.getById(id);

  @override
  Future<List<Session>> getByIds(List<String> sessionIds) =>
      _raw.getByIds(sessionIds);

  @override
  Future<Session> create() => _raw.create();

  @override
  Future<void> addInstance(String sessionId, String instanceId) =>
      _raw.addInstance(sessionId, instanceId);

  @override
  Future<void> removeInstance(String sessionId, String instanceId) =>
      _raw.removeInstance(sessionId, instanceId);

  @override
  Future<void> addParticipant(
          String sessionId, AdventureCharacter participant) =>
      _raw.addParticipant(sessionId, participant);

  @override
  Future<void> removeParticipant(String sessionId, String participantId) =>
      _raw.removeParticipant(sessionId, participantId);

  @override
  Future<void> delete(String id) => _raw.delete(id);

  @override
  Stream<List<Session>> watchByIds(List<String> sessionIds) =>
      _raw.watchByIds(sessionIds);
}
