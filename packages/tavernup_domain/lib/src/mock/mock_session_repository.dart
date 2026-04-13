import '../models/adventure_character.dart';
import '../models/session.dart';
import '../repositories/i_session_repository.dart';

/// In-memory implementation of [ISessionRepository] for testing.
class MockSessionRepository implements ISessionRepository {
  final Map<String, Session> _store = {};

  void seed(List<Session> sessions) {
    for (final s in sessions) {
      _store[s.id] = s;
    }
  }

  @override
  Future<Session?> getById(String id) async => _store[id];

  @override
  Future<List<Session>> getByIds(List<String> sessionIds) async =>
      sessionIds.map((id) => _store[id]).whereType<Session>().toList();

  @override
  Future<Session> create() async {
    final session = Session(
      id: 'session-${_store.length + 1}',
      createdBy: 'mock-user',
      createdAt: DateTime.now(),
    );
    _store[session.id] = session;
    return session;
  }

  @override
  Future<void> addInstance(String sessionId, String instanceId) async {
    final session = _store[sessionId];
    if (session == null) return;
    if (!session.instanceIds.contains(instanceId)) {
      _store[sessionId] = session.copyWith(
        instanceIds: [...session.instanceIds, instanceId],
      );
    }
  }

  @override
  Future<void> removeInstance(String sessionId, String instanceId) async {
    final session = _store[sessionId];
    if (session == null) return;
    _store[sessionId] = session.copyWith(
      instanceIds: session.instanceIds.where((id) => id != instanceId).toList(),
    );
  }

  @override
  Future<void> addParticipant(
      String sessionId, AdventureCharacter participant) async {
    final session = _store[sessionId];
    if (session == null) return;
    _store[sessionId] = session.copyWith(
      participants: [...session.participants, participant],
    );
  }

  @override
  Future<void> removeParticipant(String sessionId, String participantId) async {
    final session = _store[sessionId];
    if (session == null) return;
    _store[sessionId] = session.copyWith(
      participants:
          session.participants.where((p) => p.id != participantId).toList(),
    );
  }

  @override
  Future<void> delete(String id) async => _store.remove(id);

  @override
  Stream<List<Session>> watchByIds(List<String> sessionIds) => Stream.value(
        sessionIds.map((id) => _store[id]).whereType<Session>().toList(),
      );
}
