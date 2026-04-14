import 'package:supabase/supabase.dart' hide Session, User;
import 'package:tavernup_domain/tavernup_domain.dart';

/// Supabase implementation of [ISessionRepository].
///
/// Reads and writes to the `sessions` table in Supabase.
class SupabaseSessionRepository implements ISessionRepository {
  final SupabaseClient _client;

  SupabaseSessionRepository(this._client);

  @override
  Future<Session?> getById(String id) async {
    final data =
        await _client.from('sessions').select().eq('id', id).maybeSingle();
    return data != null ? Session.fromJson(data) : null;
  }

  @override
  Future<List<Session>> getByIds(List<String> sessionIds) async {
    if (sessionIds.isEmpty) return [];
    final data =
        await _client.from('sessions').select().inFilter('id', sessionIds);
    return (data as List).map((e) => Session.fromJson(e)).toList();
  }

  @override
  Future<Session> create() async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('sessions')
        .insert({
          'created_by': userId,
        })
        .select()
        .single();
    return Session.fromJson(data);
  }

  @override
  Future<void> addInstance(String sessionId, String instanceId) async {
    final session = await getById(sessionId);
    if (session == null) return;
    final updated = [...session.instanceIds, instanceId];
    await _client
        .from('sessions')
        .update({'instance_ids': updated}).eq('id', sessionId);
  }

  @override
  Future<void> removeInstance(String sessionId, String instanceId) async {
    final session = await getById(sessionId);
    if (session == null) return;
    final updated =
        session.instanceIds.where((id) => id != instanceId).toList();
    await _client
        .from('sessions')
        .update({'instance_ids': updated}).eq('id', sessionId);
  }

  @override
  Future<void> addParticipant(
      String sessionId, AdventureCharacter participant) async {
    final session = await getById(sessionId);
    if (session == null) return;
    final updated = [...session.participants, participant];
    await _client.from('sessions').update({
      'participants': updated.map((p) => p.toJson()).toList(),
    }).eq('id', sessionId);
  }

  @override
  Future<void> removeParticipant(String sessionId, String participantId) async {
    final session = await getById(sessionId);
    if (session == null) return;
    final updated =
        session.participants.where((p) => p.id != participantId).toList();
    await _client.from('sessions').update({
      'participants': updated.map((p) => p.toJson()).toList(),
    }).eq('id', sessionId);
  }

  @override
  Future<void> delete(String id) async {
    await _client.from('sessions').delete().eq('id', id);
  }

  @override
  Stream<List<Session>> watchByIds(List<String> sessionIds) {
    if (sessionIds.isEmpty) return Stream.value([]);
    return _client
        .from('sessions')
        .stream(primaryKey: ['id'])
        .inFilter('id', sessionIds)
        .map((data) => data.map((e) => Session.fromJson(e)).toList());
  }
}
