import 'package:supabase/supabase.dart' hide User;
import 'package:tavernup_domain/tavernup_domain.dart';

/// Supabase implementation of [ICharacterRepository].
///
/// Reads and writes to the `characters` table in Supabase.
class SupabaseCharacterRepository implements ICharacterRepository {
  final SupabaseClient _client;

  SupabaseCharacterRepository(this._client);

  @override
  Future<List<Character>> getOwned(String ownerId) async {
    final data =
        await _client.from('characters').select().eq('owner_id', ownerId);
    return (data as List).map((e) => Character.fromJson(e)).toList();
  }

  @override
  Future<List<Character>> getVisible(String userId) async {
    final data = await _client
        .from('characters')
        .select()
        .or('owner_id.eq.$userId,visible_for.cs.{"$userId"}');
    return (data as List).map((e) => Character.fromJson(e)).toList();
  }

  @override
  Future<Character?> getById(String id) async {
    final data =
        await _client.from('characters').select().eq('id', id).maybeSingle();
    return data != null ? Character.fromJson(data) : null;
  }

  @override
  Future<void> save(Character character) async {
    await _client.from('characters').upsert(character.toJson());
  }

  @override
  Future<void> delete(String id) async {
    await _client.from('characters').delete().eq('id', id);
  }

  @override
  Future<void> grantVisibility(String characterId, String userId) async {
    final character = await getById(characterId);
    if (character == null) return;
    final updated = [...character.visibleFor, userId];
    await _client
        .from('characters')
        .update({'visible_for': updated}).eq('id', characterId);
  }

  @override
  Future<void> revokeVisibility(String characterId, String userId) async {
    final character = await getById(characterId);
    if (character == null) return;
    final updated = character.visibleFor.where((id) => id != userId).toList();
    await _client
        .from('characters')
        .update({'visible_for': updated}).eq('id', characterId);
  }

  @override
  Stream<List<Character>> watchOwned(String ownerId) {
    return _client
        .from('characters')
        .stream(primaryKey: ['id'])
        .eq('owner_id', ownerId)
        .map((data) => data.map((e) => Character.fromJson(e)).toList());
  }
}
