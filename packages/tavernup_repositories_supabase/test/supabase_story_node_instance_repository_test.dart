import 'package:supabase/supabase.dart' hide User;
import 'package:tavernup_domain/tavernup_domain.dart';
import 'package:tavernup_repositories_supabase/src/supabase_story_node_instance_repository.dart';
import 'package:test/test.dart';

import 'test_client.dart';

void main() {
  late SupabaseClient client;
  late SupabaseStoryNodeInstanceRepository repository;

  setUp(() async {
    client = createTestClient();
    repository = SupabaseStoryNodeInstanceRepository(client);
    await cleanTestData(client);
  });

  Future<String> setupAuthAndDomainUser(String name) async {
    final authId = await createTestAuthUser(client, testEmail(name));
    await client.from('users').insert({
      'id': authId,
      'nickname': name,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    return authId;
  }

  Future<StoryNode> createNodeDirectly(String createdBy) async {
    final data = await client
        .from('story_nodes')
        .insert({
          'title': 'Test Node',
          'created_by': createdBy,
          'child_ids': [],
          'character_ids': [],
        })
        .select()
        .single();
    return StoryNode.fromJson(data);
  }

  Future<StoryNodeInstance> createInstanceDirectly({
    required String templateId,
    required String createdBy,
    StoryNodeStatus status = StoryNodeStatus.preparation,
  }) async {
    final data = await client
        .from('story_node_instances')
        .insert({
          'template_id': templateId,
          'created_by': createdBy,
          'status': status.name,
        })
        .select()
        .single();
    return StoryNodeInstance.fromJson(data);
  }

  group('SupabaseStoryNodeInstanceRepository', () {
    test('create and getById round-trip', () async {
      final userId = await setupAuthAndDomainUser('user');
      final node = await createNodeDirectly(userId);
      final instance = await createInstanceDirectly(
        templateId: node.id,
        createdBy: userId,
      );

      final loaded = await repository.getById(instance.id);
      expect(loaded, isNotNull);
      expect(loaded!.id, equals(instance.id));
      expect(loaded.templateId, equals(node.id));
    });

    test('getById returns null for unknown id', () async {
      final result =
          await repository.getById('00000000-0000-0000-0000-000000000099');
      expect(result, isNull);
    });

    test('getOrCreate is idempotent', () async {
      final userId = await setupAuthAndDomainUser('user');
      final node = await createNodeDirectly(userId);

      final instance1 = await createInstanceDirectly(
        templateId: node.id,
        createdBy: userId,
      );
      final instance2 = await repository.getById(instance1.id);

      expect(instance2!.id, equals(instance1.id));
    });

    test('updateStatus changes status', () async {
      final userId = await setupAuthAndDomainUser('user');
      final node = await createNodeDirectly(userId);
      final instance = await createInstanceDirectly(
        templateId: node.id,
        createdBy: userId,
      );

      await repository.updateStatus(instance.id, StoryNodeStatus.completed);
      final loaded = await repository.getById(instance.id);
      expect(loaded!.status, equals(StoryNodeStatus.completed));
    });

    test('delete removes instance', () async {
      final userId = await setupAuthAndDomainUser('user');
      final node = await createNodeDirectly(userId);
      final instance = await createInstanceDirectly(
        templateId: node.id,
        createdBy: userId,
      );

      await repository.delete(instance.id);
      final loaded = await repository.getById(instance.id);
      expect(loaded, isNull);
    });

    test('getForTemplate returns all instances for template', () async {
      final userId = await setupAuthAndDomainUser('user');
      final node = await createNodeDirectly(userId);

      final i1 =
          await createInstanceDirectly(templateId: node.id, createdBy: userId);
      final i2 =
          await createInstanceDirectly(templateId: node.id, createdBy: userId);

      final instances = await repository.getForTemplate(node.id);
      expect(instances.map((i) => i.id), containsAll([i1.id, i2.id]));
    });
  });
}
