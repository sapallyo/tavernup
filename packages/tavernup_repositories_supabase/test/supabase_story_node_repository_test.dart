import 'package:supabase/supabase.dart' hide User;
import 'package:tavernup_domain/tavernup_domain.dart';
import 'package:tavernup_repositories_supabase/tavernup_repositories_supabase.dart';
import 'package:test/test.dart';

import 'test_client.dart';

void main() {
  late SupabaseClient client;
  late SupabaseStoryNodeRepository repository;

  setUp(() async {
    client = createTestClient();
    repository = SupabaseStoryNodeRepository(client);
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

  Future<StoryNode> createNodeDirectly({
    required String createdBy,
    String title = 'Test Node',
    String? parentId,
  }) async {
    final data = await client
        .from('story_nodes')
        .insert({
          'title': title,
          'created_by': createdBy,
          'child_ids': [],
          'character_ids': [],
          if (parentId != null) 'parent_id': parentId,
        })
        .select()
        .single();
    return StoryNode.fromJson(data);
  }

  group('SupabaseStoryNodeRepository', () {
    test('create and getById round-trip', () async {
      final userId = await setupAuthAndDomainUser('user');
      final node = await createNodeDirectly(createdBy: userId);

      final loaded = await repository.getById(node.id);
      expect(loaded, isNotNull);
      expect(loaded!.id, equals(node.id));
      expect(loaded.title, equals('Test Node'));
    });

    test('getById returns null for unknown id', () async {
      final result =
          await repository.getById('00000000-0000-0000-0000-000000000099');
      expect(result, isNull);
    });

    test('getRoots returns only root nodes for user', () async {
      final userId = await setupAuthAndDomainUser('user');
      final root = await createNodeDirectly(createdBy: userId, title: 'Root');
      final child = await createNodeDirectly(
        createdBy: userId,
        title: 'Child',
        parentId: root.id,
      );

      final roots = await repository.getRoots(userId);
      expect(roots.map((n) => n.id), contains(root.id));
      expect(roots.map((n) => n.id), isNot(contains(child.id)));
    });

    test('getChildren returns direct children of parent', () async {
      final userId = await setupAuthAndDomainUser('user');
      final parent =
          await createNodeDirectly(createdBy: userId, title: 'Parent');
      final child1 = await createNodeDirectly(
        createdBy: userId,
        title: 'Child 1',
        parentId: parent.id,
      );
      final child2 = await createNodeDirectly(
        createdBy: userId,
        title: 'Child 2',
        parentId: parent.id,
      );

      final children = await repository.getChildren(parent.id);
      expect(children.map((n) => n.id), containsAll([child1.id, child2.id]));
    });

    test('delete removes node', () async {
      final userId = await setupAuthAndDomainUser('user');
      final node = await createNodeDirectly(createdBy: userId);

      await repository.delete(node.id);
      final loaded = await repository.getById(node.id);
      expect(loaded, isNull);
    });

    test('delete parent sets child parent_id to null', () async {
      final userId = await setupAuthAndDomainUser('user');
      final parent =
          await createNodeDirectly(createdBy: userId, title: 'Parent');
      final child = await createNodeDirectly(
        createdBy: userId,
        title: 'Child',
        parentId: parent.id,
      );

      await repository.delete(parent.id);
      final loadedChild = await repository.getById(child.id);
      expect(loadedChild, isNotNull);
      expect(loadedChild!.parentId, isNull);
    });
  });
}
