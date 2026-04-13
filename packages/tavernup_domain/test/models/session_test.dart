import 'package:test/test.dart';
import 'package:tavernup_domain/tavernup_domain.dart';

void main() {
  group('Session', () {
    final participant = AdventureCharacter(
      id: 'ac-1',
      userId: 'user-1',
      characterId: 'char-1',
      addedAt: DateTime(2024, 1, 15),
    );

    final session = Session(
      id: 'session-1',
      instanceIds: ['inst-1', 'inst-2'],
      participants: [participant],
      createdBy: 'user-1',
      createdAt: DateTime(2024, 1, 15),
    );

    group('serialisation', () {
      test('toJson contains instanceIds and participants', () {
        final json = session.toJson();
        expect(json['instance_ids'], ['inst-1', 'inst-2']);
        expect((json['participants'] as List).length, 1);
      });

      test('fromJson roundtrip', () {
        final json = session.toJson()
          ..['created_at'] = session.createdAt.toIso8601String();
        final restored = Session.fromJson(json);
        expect(restored.id, session.id);
        expect(restored.instanceIds, session.instanceIds);
        expect(restored.participants.length, 1);
        expect(restored.participants.first.userId, 'user-1');
      });

      test('fromJson defaults to empty lists', () {
        final json = {
          'id': 'session-1',
          'created_by': 'user-1',
          'created_at': '2024-01-15T00:00:00.000',
        };
        final s = Session.fromJson(json);
        expect(s.instanceIds, isEmpty);
        expect(s.participants, isEmpty);
      });
    });

    group('copyWith', () {
      test('updates instanceIds', () {
        final updated = session.copyWith(
          instanceIds: ['inst-1', 'inst-2', 'inst-3'],
        );
        expect(updated.instanceIds.length, 3);
      });

      test('updates participants', () {
        final updated = session.copyWith(participants: []);
        expect(updated.participants, isEmpty);
      });
    });
  });
}
