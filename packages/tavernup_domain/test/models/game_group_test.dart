import 'package:test/test.dart';
import 'package:tavernup_domain/tavernup_domain.dart';

void main() {
  group('GameGroup', () {
    final gameGroup = GameGroup(
      id: 'group-1',
      name: 'Shadowrun Runde',
      createdBy: 'user-1',
      createdAt: DateTime(2024, 1, 15),
      sessionIds: ['session-1', 'session-2'],
    );

    group('serialisation', () {
      test('toJson contains sessionIds', () {
        final json = gameGroup.toJson();
        expect(json['session_ids'], ['session-1', 'session-2']);
      });

      test('fromJson roundtrip', () {
        final json = {
          ...gameGroup.toJson(),
          'created_at': gameGroup.createdAt.toIso8601String(),
        };
        final restored = GameGroup.fromJson(json);
        expect(restored.id, gameGroup.id);
        expect(restored.sessionIds, gameGroup.sessionIds);
        expect(restored.ruleset, 'generic');
      });

      test('fromJson defaults sessionIds to empty list', () {
        final json = {
          'id': 'group-1',
          'name': 'Test',
          'created_by': 'user-1',
          'created_at': '2024-01-15T00:00:00.000',
        };
        expect(GameGroup.fromJson(json).sessionIds, isEmpty);
      });

      test('fromJson defaults ruleset to generic', () {
        final json = {
          'id': 'group-1',
          'name': 'Test',
          'created_by': 'user-1',
          'created_at': '2024-01-15T00:00:00.000',
        };
        expect(GameGroup.fromJson(json).ruleset, 'generic');
      });
    });

    group('copyWith', () {
      test('updates sessionIds', () {
        final updated = gameGroup.copyWith(
          sessionIds: ['session-1', 'session-2', 'session-3'],
        );
        expect(updated.sessionIds.length, 3);
      });

      test('clearDescription sets description to null', () {
        final withDesc = gameGroup.copyWith(description: 'Beschreibung');
        final cleared = withDesc.copyWith(clearDescription: true);
        expect(cleared.description, isNull);
      });
    });
  });
}
