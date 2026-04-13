import 'package:test/test.dart';
import 'package:tavernup_domain/tavernup_domain.dart';

void main() {
  group('MockSessionRepository', () {
    late MockSessionRepository repo;

    setUp(() => repo = MockSessionRepository());

    test('create stores and returns session', () async {
      final session = await repo.create();
      expect(await repo.getById(session.id), isNotNull);
      expect(session.instanceIds, isEmpty);
      expect(session.participants, isEmpty);
    });

    test('getByIds returns matching sessions', () async {
      final s1 = await repo.create();
      final s2 = await repo.create();
      final results = await repo.getByIds([s1.id, s2.id]);
      expect(results.length, 2);
    });

    test('getByIds skips unknown ids', () async {
      final s1 = await repo.create();
      final results = await repo.getByIds([s1.id, 'unknown']);
      expect(results.length, 1);
    });

    test('addInstance appends instanceId', () async {
      final session = await repo.create();
      await repo.addInstance(session.id, 'inst-1');
      final updated = await repo.getById(session.id);
      expect(updated?.instanceIds, contains('inst-1'));
    });

    test('addInstance does not duplicate', () async {
      final session = await repo.create();
      await repo.addInstance(session.id, 'inst-1');
      await repo.addInstance(session.id, 'inst-1');
      final updated = await repo.getById(session.id);
      expect(updated?.instanceIds.length, 1);
    });

    test('removeInstance removes instanceId', () async {
      final session = await repo.create();
      await repo.addInstance(session.id, 'inst-1');
      await repo.removeInstance(session.id, 'inst-1');
      final updated = await repo.getById(session.id);
      expect(updated?.instanceIds, isEmpty);
    });

    test('addParticipant appends participant', () async {
      final session = await repo.create();
      final participant = AdventureCharacter(
        id: 'ac-1',
        userId: 'user-1',
        characterId: 'char-1',
        addedAt: DateTime.now(),
      );
      await repo.addParticipant(session.id, participant);
      final updated = await repo.getById(session.id);
      expect(updated?.participants.length, 1);
    });

    test('removeParticipant removes by id', () async {
      final session = await repo.create();
      final participant = AdventureCharacter(
        id: 'ac-1',
        userId: 'user-1',
        characterId: 'char-1',
        addedAt: DateTime.now(),
      );
      await repo.addParticipant(session.id, participant);
      await repo.removeParticipant(session.id, 'ac-1');
      final updated = await repo.getById(session.id);
      expect(updated?.participants, isEmpty);
    });

    test('delete removes session', () async {
      final session = await repo.create();
      await repo.delete(session.id);
      expect(await repo.getById(session.id), isNull);
    });

    test('watchByIds emits matching sessions', () async {
      final s1 = await repo.create();
      final stream = repo.watchByIds([s1.id]);
      final result = await stream.first;
      expect(result.length, 1);
      expect(result.first.id, s1.id);
    });
  });
}
