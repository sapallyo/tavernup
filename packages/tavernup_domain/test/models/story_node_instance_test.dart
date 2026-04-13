import 'package:test/test.dart';
import 'package:tavernup_domain/tavernup_domain.dart';

void main() {
  group('StoryNodeInstance', () {
    final instance = StoryNodeInstance(
      id: 'inst-1',
      templateId: 'node-1',
      createdBy: 'user-1',
      createdAt: DateTime(2024, 1, 15),
    );

    group('serialisation', () {
      test('toJson contains all fields', () {
        final json = instance.toJson();
        expect(json['id'], 'inst-1');
        expect(json['template_id'], 'node-1');
        expect(json['status'], 'preparation');
      });

      test('fromJson roundtrip', () {
        final json = instance.toJson()
          ..['created_at'] = instance.createdAt.toIso8601String();
        final restored = StoryNodeInstance.fromJson(json);
        expect(restored.id, instance.id);
        expect(restored.templateId, instance.templateId);
        expect(restored.status, StoryNodeStatus.preparation);
      });

      test('fromJson defaults status to preparation', () {
        final json = {
          'id': 'inst-1',
          'template_id': 'node-1',
          'created_by': 'user-1',
          'created_at': '2024-01-15T00:00:00.000',
          'status': 'unknown',
        };
        expect(StoryNodeInstance.fromJson(json).status,
            StoryNodeStatus.preparation);
      });
    });

    group('copyWith', () {
      test('updates status', () {
        final updated = instance.copyWith(status: StoryNodeStatus.active);
        expect(updated.status, StoryNodeStatus.active);
        expect(updated.id, instance.id);
      });
    });

    group('StoryNodeStatus', () {
      test('fromString parses all values', () {
        expect(StoryNodeStatus.fromString('preparation'),
            StoryNodeStatus.preparation);
        expect(StoryNodeStatus.fromString('active'), StoryNodeStatus.active);
        expect(
            StoryNodeStatus.fromString('completed'), StoryNodeStatus.completed);
      });

      test('displayName is in German', () {
        expect(StoryNodeStatus.preparation.displayName, 'Vorbereitung');
        expect(StoryNodeStatus.active.displayName, 'Aktiv');
        expect(StoryNodeStatus.completed.displayName, 'Abgeschlossen');
      });
    });
  });
}
