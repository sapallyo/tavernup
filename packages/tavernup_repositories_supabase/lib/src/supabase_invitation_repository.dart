import 'package:supabase/supabase.dart' hide User;
import 'package:tavernup_domain/tavernup_domain.dart';

/// Supabase implementation of [IInvitationRepository].
///
/// Reads and writes to the `invitations` table in Supabase.
class SupabaseInvitationRepository implements IInvitationRepository {
  final SupabaseClient _client;

  SupabaseInvitationRepository(this._client);

  @override
  String get entityType => 'invitation';

  @override
  Future<Invitation> createInvitation(
    String gameGroupId,
    GameGroupRole role,
    String invitedUserId,
  ) async {
    final data = await _client
        .from('invitations')
        .insert({
          'game_group_id': gameGroupId,
          'role': role.name,
          'created_by': _client.auth.currentUser!.id,
          'invited_user_id': invitedUserId,
          'expires_at':
              DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        })
        .select()
        .single();
    return Invitation.fromJson(data);
  }

  @override
  Future<Invitation?> getById(String id) async {
    final data =
        await _client.from('invitations').select().eq('id', id).maybeSingle();
    return data != null ? Invitation.fromJson(data) : null;
  }

  @override
  Future<List<Invitation>> getForUser(String userId) async {
    final data = await _client
        .from('invitations')
        .select()
        .eq('invited_user_id', userId)
        .eq('status', 'pending');
    return (data as List).map((e) => Invitation.fromJson(e)).toList();
  }

  @override
  Future<List<Invitation>> getForGameGroup(String gameGroupId) async {
    final data = await _client
        .from('invitations')
        .select()
        .eq('game_group_id', gameGroupId);
    return (data as List).map((e) => Invitation.fromJson(e)).toList();
  }

  @override
  Future<String> create(Map<String, dynamic> data) async {
    final result = await _client
        .from('invitations')
        .insert({
          'game_group_id': data['gameGroupId'],
          'role': data['role'] ?? 'player',
          'created_by': _client.auth.currentUser!.id,
          'invited_user_id': data['invitedUserId'],
          'expires_at':
              DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        })
        .select('id')
        .single();
    return result['id'] as String;
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    await _client.from('invitations').update(data).eq('id', id);
  }

  @override
  Future<void> delete(String id) async {
    await _client.from('invitations').delete().eq('id', id);
  }
}
