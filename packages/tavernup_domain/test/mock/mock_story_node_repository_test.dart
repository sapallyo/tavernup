import 'package:test/test.dart';
import 'package:tavernup_domain/tavernup_domain.dart';

void main() {
  group('MockStoryNodeRepository', () {
    late MockStoryNodeRepository repo;

    final root = StoryNode(
      id: 'node-1',
      title: 'Shadowrun Kampagne',
      createdBy: 'user-1',
      createdAt: DateTime(2024, 1, 15),
    );

    final child = StoryNode(
      id: 'node-2',
      title: 'Abenteuer 1',
      parentId: 'node-1',
      createdBy: 'user-1',
      createdAt: DateTime(2024, 1, 15),
    );

    setUp(() {
      repo = MockStoryNodeRepository();
      repo.seed([root, child]);
    });

    test('getRoots returns only root nodes for user', () async {
      final roots = await repo.getRoots('user-1');
      expect(roots.length, 1);
      expect(roots.first.id, 'node-1');
    });

    test('getRoots returns empty for unknown user', () async {
      expect(await repo.getRoots('unknown'), isEmpty);
    });

    test('getChildren returns direct children', () async {
      final children = await repo.getChildren('node-1');
      expect(children.length, 1);
      expect(children.first.id, 'node-2');
    });

    test('getChildren returns empty for leaf node', () async {
      expect(await repo.getChildren('node-2'), isEmpty);
    });

    test('getById returns correct node', () async {
      expect((await repo.getById('node-1'))?.title, 'Shadowrun Kampagne');
    });

    test('getById returns null for unknown id', () async {
      expect(await repo.getById('unknown'), isNull);
    });

    test('create adds root node when no parentId', () async {
      final node = await repo.create(title: 'Neue Kampagne');
      expect(node.isRoot, isTrue);
      expect(await repo.getById(node.id), isNotNull);
    });

    test('create adds child node with parentId', () async {
      final node = await repo.create(
        title: 'Kapitel 1',
        parentId: 'node-1',
      );
      expect(node.parentId, 'node-1');
      expect(node.isRoot, isFalse);
    });

    test('save updates existing node', () async {
      final updated = root.copyWith(title: 'Neuer Titel');
      await repo.save(updated);
      expect((await repo.getById('node-1'))?.title, 'Neuer Titel');
    });

    test('delete removes node', () async {
      await repo.delete('node-2');
      expect(await repo.getById('node-2'), isNull);
    });

    test('watchChildren emits children', () async {
      final stream = repo.watchChildren('node-1');
      final result = await stream.first;
      expect(result.length, 1);
      expect(result.first.id, 'node-2');
    });
  });
}
