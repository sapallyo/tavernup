import 'package:supabase/supabase.dart' hide User;
import 'package:tavernup_domain/tavernup_domain.dart';

/// Supabase implementation of [IGameGroupRepository].
///
/// Reads and writes to the `game_groups` and `game_group_memberships`
/// tables in Supabase.
class SupabaseGameGroupRepository implements IGameGroupRepository {
  final SupabaseClient _client;

  SupabaseGameGroupRepository(this._client);

  @override
  String get entityType => 'membership';

  @override
  Future<List<GameGroup>> getAll(String userId) async {
    final memberships = await _client
        .from('game_group_memberships')
        .select('game_group_id')
        .eq('user_id', userId);
    final ids =
        (memberships as List).map((m) => m['game_group_id'] as String).toList();
    if (ids.isEmpty) return [];
    final data = await _client.from('game_groups').select().inFilter('id', ids);
    return (data as List).map((e) => GameGroup.fromJson(e)).toList();
  }

  @override
  Future<GameGroup?> getById(String id) async {
    final data =
        await _client.from('game_groups').select().eq('id', id).maybeSingle();
    return data != null ? GameGroup.fromJson(data) : null;
  }

  @override
  Future<GameGroup> createGameGroup(
      String name, String? description, String ruleset) async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('game_groups')
        .insert({
          'name': name,
          if (description != null) 'description': description,
          'created_by': userId,
          'ruleset': ruleset,
        })
        .select()
        .single();
    final group = GameGroup.fromJson(data);
    await addMember(group.id, userId, GameGroupRole.admin);
    return group;
  }

  @override
  Future<void> addMember(
      String gameGroupId, String userId, GameGroupRole role) async {
    await _client.from('game_group_memberships').insert({
      'game_group_id': gameGroupId,
      'user_id': userId,
      'role': role.name,
    });
  }

  @override
  Future<void> removeMember(
      String gameGroupId, String userId, GameGroupRole role) async {
    await _client
        .from('game_group_memberships')
        .delete()
        .eq('game_group_id', gameGroupId)
        .eq('user_id', userId);
  }

  @override
  Future<List<GameGroupMembership>> getMembers(String gameGroupId) async {
    final data = await _client
        .from('game_group_memberships')
        .select()
        .eq('game_group_id', gameGroupId);
    return (data as List).map((e) => GameGroupMembership.fromJson(e)).toList();
  }

  @override
  Future<List<(GameGroupMembership, User?)>> getMembersWithProfiles(
      String gameGroupId) async {
    final data = await _client
        .from('game_group_memberships')
        .select('*, users(*)')
        .eq('game_group_id', gameGroupId);
    return (data as List).map((e) {
      final membership = GameGroupMembership.fromJson(e);
      final userJson = e['users'] as Map<String, dynamic>?;
      final user = userJson != null ? User.fromJson(userJson) : null;
      return (membership, user);
    }).toList();
  }

  @override
  Future<List<GameGroupRole>> getRolesForUser(
      String gameGroupId, String userId) async {
    final data = await _client
        .from('game_group_memberships')
        .select('role')
        .eq('game_group_id', gameGroupId)
        .eq('user_id', userId);
    return (data as List)
        .map((e) => GameGroupRole.fromString(e['role'] as String))
        .toList();
  }

  @override
  Stream<List<GameGroup>> watchAll(String userId) {
    return _client
        .from('game_group_memberships')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .asyncMap((memberships) async {
          final ids =
              memberships.map((m) => m['game_group_id'] as String).toList();
          if (ids.isEmpty) return <GameGroup>[];
          final data =
              await _client.from('game_groups').select().inFilter('id', ids);
          return (data as List).map((e) => GameGroup.fromJson(e)).toList();
        });
  }

  @override
  Future<String> create(Map<String, dynamic> data) async {
    final result = await _client
        .from('game_group_memberships')
        .insert({
          'game_group_id': data['gameGroupId'],
          'user_id': data['userId'],
          'role': data['role'] ?? 'player',
          if (data['invitedBy'] != null) 'invited_by': data['invitedBy'],
        })
        .select('id')
        .single();
    return result['id'] as String;
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    await _client.from('game_group_memberships').update(data).eq('id', id);
  }

  @override
  Future<void> delete(String id) async {
    await _client.from('game_group_memberships').delete().eq('id', id);
  }
}
