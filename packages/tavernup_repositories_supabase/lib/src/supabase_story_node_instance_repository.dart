import 'package:supabase/supabase.dart' hide User, Session;
import 'package:tavernup_domain/tavernup_domain.dart';

/// Supabase implementation of [IStoryNodeInstanceRepository].
///
/// Reads and writes to the `story_node_instances` table in Supabase.
class SupabaseStoryNodeInstanceRepository
    implements IStoryNodeInstanceRepository {
  final SupabaseClient _client;

  SupabaseStoryNodeInstanceRepository(this._client);

  @override
  Future<StoryNodeInstance?> getById(String id) async {
    final data = await _client
        .from('story_node_instances')
        .select()
        .eq('id', id)
        .maybeSingle();
    return data != null ? StoryNodeInstance.fromJson(data) : null;
  }

  @override
  Future<List<StoryNodeInstance>> getForTemplate(String templateId) async {
    final data = await _client
        .from('story_node_instances')
        .select()
        .eq('template_id', templateId);
    return (data as List).map((e) => StoryNodeInstance.fromJson(e)).toList();
  }

  @override
  Future<StoryNodeInstance> getOrCreate(String templateId) async {
    final existing = await _client
        .from('story_node_instances')
        .select()
        .eq('template_id', templateId)
        .maybeSingle();
    if (existing != null) return StoryNodeInstance.fromJson(existing);

    final data = await _client
        .from('story_node_instances')
        .insert({
          'template_id': templateId,
          'created_by': _client.auth.currentUser!.id,
        })
        .select()
        .single();
    return StoryNodeInstance.fromJson(data);
  }

  @override
  Future<void> updateStatus(String id, StoryNodeStatus status) async {
    await _client
        .from('story_node_instances')
        .update({'status': status.name}).eq('id', id);
  }

  @override
  Future<void> delete(String id) async {
    await _client.from('story_node_instances').delete().eq('id', id);
  }
}
