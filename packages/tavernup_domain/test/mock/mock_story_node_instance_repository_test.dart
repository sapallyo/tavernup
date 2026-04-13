import 'package:test/test.dart';
import 'package:tavernup_domain/tavernup_domain.dart';

void main() {
  group('MockStoryNodeInstanceRepository', () {
    late MockStoryNodeInstanceRepository repo;

    final instance = StoryNodeInstance(
      id: 'inst-1',
      templateId: 'node-1',
      createdBy: 'user-1',
      createdAt: DateTime(2024, 1, 15),
    );

    setUp(() {
      repo = MockStoryNodeInstanceRepository();
      repo.seed([instance]);
    });

    test('getById returns correct instance', () async {
      expect((await repo.getById('inst-1'))?.templateId, 'node-1');
    });

    test('getById returns null for unknown id', () async {
      expect(await repo.getById('unknown'), isNull);
    });

    test('getForTemplate returns matching instances', () async {
      final results = await repo.getForTemplate('node-1');
      expect(results.length, 1);
      expect(results.first.id, 'inst-1');
    });

    test('getForTemplate returns empty for unknown template', () async {
      expect(await repo.getForTemplate('unknown'), isEmpty);
    });

    test('getOrCreate returns existing instance', () async {
      final result = await repo.getOrCreate('node-1');
      expect(result.id, 'inst-1');
    });

    test('getOrCreate creates new instance when none exists', () async {
      final result = await repo.getOrCreate('node-99');
      expect(result.templateId, 'node-99');
      expect(await repo.getById(result.id), isNotNull);
    });

    test('getOrCreate does not duplicate', () async {
      await repo.getOrCreate('node-1');
      await repo.getOrCreate('node-1');
      final results = await repo.getForTemplate('node-1');
      expect(results.length, 1);
    });

    test('updateStatus changes status', () async {
      await repo.updateStatus('inst-1', StoryNodeStatus.active);
      final updated = await repo.getById('inst-1');
      expect(updated?.status, StoryNodeStatus.active);
    });

    test('updateStatus has no effect for unknown id', () async {
      await repo.updateStatus('unknown', StoryNodeStatus.active);
      expect(
          (await repo.getById('inst-1'))?.status, StoryNodeStatus.preparation);
    });

    test('delete removes instance', () async {
      await repo.delete('inst-1');
      expect(await repo.getById('inst-1'), isNull);
    });
  });
}
