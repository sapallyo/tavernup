import 'package:test/test.dart';
import 'package:tavernup_domain/tavernup_domain.dart';

void main() {
  group('StatModifier', () {
    final modifier = StatModifier(
      sourceId: 'spell-1',
      sourceName: 'Stärke steigern',
      value: 2,
      type: ModifierType.spell,
    );

    group('serialisation', () {
      test('toJson / fromJson roundtrip', () {
        final json = modifier.toJson();
        final restored = StatModifier.fromJson(json);
        expect(restored, equals(modifier));
      });

      test('fromJson defaults to situational for unknown type', () {
        final json = {
          'source_id': 'x',
          'source_name': 'Unknown',
          'value': 1,
          'type': 'unknown_type',
        };
        final mod = StatModifier.fromJson(json);
        expect(mod.type, ModifierType.situational);
      });
    });

    group('equality', () {
      test('same fields are equal', () {
        final mod2 = StatModifier(
          sourceId: 'spell-1',
          sourceName: 'Stärke steigern',
          value: 2,
          type: ModifierType.spell,
        );
        expect(modifier, equals(mod2));
      });
    });
  });
}
