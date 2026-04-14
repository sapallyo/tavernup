import 'package:supabase/supabase.dart' hide User, Session;
import 'package:tavernup_domain/tavernup_domain.dart';

/// Supabase implementation of [IStoryNodeRepository].
///
/// Reads and writes to the `story_nodes` table in Supabase.
class SupabaseStoryNodeRepository implements IStoryNodeRepository {
  final SupabaseClient _client;

  SupabaseStoryNodeRepository(this._client);

  @override
  Future<List<StoryNode>> getRoots(String userId) async {
    final data = await _client
        .from('story_nodes')
        .select()
        .eq('created_by', userId)
        .isFilter('parent_id', null);
    return (data as List).map((e) => StoryNode.fromJson(e)).toList();
  }

  @override
  Future<List<StoryNode>> getChildren(String parentId) async {
    final data =
        await _client.from('story_nodes').select().eq('parent_id', parentId);
    return (data as List).map((e) => StoryNode.fromJson(e)).toList();
  }

  @override
  Future<StoryNode?> getById(String id) async {
    final data =
        await _client.from('story_nodes').select().eq('id', id).maybeSingle();
    return data != null ? StoryNode.fromJson(data) : null;
  }

  @override
  Future<StoryNode> create({
    required String title,
    String? description,
    String? imageUrl,
    String? systemKey,
    String? parentId,
  }) async {
    final data = await _client
        .from('story_nodes')
        .insert({
          'title': title,
          if (description != null) 'description': description,
          if (imageUrl != null) 'image_url': imageUrl,
          if (systemKey != null) 'system_key': systemKey,
          if (parentId != null) 'parent_id': parentId,
          'created_by': _client.auth.currentUser!.id,
        })
        .select()
        .single();
    return StoryNode.fromJson(data);
  }

  @override
  Future<void> save(StoryNode node) async {
    await _client.from('story_nodes').upsert(node.toJson());
  }

  @override
  Future<void> delete(String id) async {
    await _client.from('story_nodes').delete().eq('id', id);
  }

  @override
  Stream<List<StoryNode>> watchChildren(String parentId) {
    return _client
        .from('story_nodes')
        .stream(primaryKey: ['id'])
        .eq('parent_id', parentId)
        .map((data) => data.map((e) => StoryNode.fromJson(e)).toList());
  }
}
