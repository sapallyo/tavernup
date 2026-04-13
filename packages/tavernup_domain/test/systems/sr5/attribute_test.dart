import 'package:test/test.dart';
import 'package:tavernup_domain/tavernup_domain.dart';

void main() {
  group('Attribute', () {
    final base = Attribute(base: 4, max: 6);

    group('effective value', () {
      test('no modifiers — effective equals base', () {
        expect(base.effective, 4);
      });

      test('positive modifier increases effective', () {
        final mod = StatModifier(
          sourceId: 's1',
          sourceName: 'Boost',
          value: 2,
          type: ModifierType.spell,
        );
        expect(base.addModifier(mod).effective, 6);
      });

      test('effective is clamped to max', () {
        final mod = StatModifier(
          sourceId: 's1',
          sourceName: 'Boost',
          value: 10,
          type: ModifierType.spell,
        );
        expect(base.addModifier(mod).effective, 6);
      });

      test('negative modifier decreases effective', () {
        final mod = StatModifier(
          sourceId: 'w1',
          sourceName: 'Wunde',
          value: -2,
          type: ModifierType.wound,
        );
        expect(base.addModifier(mod).effective, 2);
      });

      test('effective is clamped to zero', () {
        final mod = StatModifier(
          sourceId: 'w1',
          sourceName: 'Wunde',
          value: -10,
          type: ModifierType.wound,
        );
        expect(base.addModifier(mod).effective, 0);
      });
    });

    group('addModifier', () {
      test('adds new modifier', () {
        final mod = StatModifier(
          sourceId: 's1',
          sourceName: 'Boost',
          value: 2,
          type: ModifierType.spell,
        );
        expect(base.addModifier(mod).modifiers.length, 1);
      });

      test('replaces existing modifier with same sourceId', () {
        final mod1 = StatModifier(
          sourceId: 's1',
          sourceName: 'Boost',
          value: 2,
          type: ModifierType.spell,
        );
        final mod2 = StatModifier(
          sourceId: 's1',
          sourceName: 'Boost',
          value: 3,
          type: ModifierType.spell,
        );
        final attr = base.addModifier(mod1).addModifier(mod2);
        expect(attr.modifiers.length, 1);
        expect(attr.effective, 7.clamp(0, 6));
      });
    });

    group('removeModifier', () {
      test('removes modifier by sourceId', () {
        final mod = StatModifier(
          sourceId: 's1',
          sourceName: 'Boost',
          value: 2,
          type: ModifierType.spell,
        );
        final attr = base.addModifier(mod).removeModifier('s1');
        expect(attr.modifiers, isEmpty);
        expect(attr.effective, 4);
      });

      test('no effect if sourceId not found', () {
        expect(base.removeModifier('nonexistent').effective, 4);
      });
    });

    group('removeModifiersOfType', () {
      test('removes all modifiers of given type', () {
        final spell = StatModifier(
          sourceId: 's1',
          sourceName: 'Spell',
          value: 2,
          type: ModifierType.spell,
        );
        final wound = StatModifier(
          sourceId: 'w1',
          sourceName: 'Wound',
          value: -1,
          type: ModifierType.wound,
        );
        final attr = base
            .addModifier(spell)
            .addModifier(wound)
            .removeModifiersOfType(ModifierType.spell);
        expect(attr.modifiers.length, 1);
        expect(attr.modifiers.first.type, ModifierType.wound);
      });
    });

    group('isMaxed', () {
      test('returns true when base equals max', () {
        expect(Attribute(base: 6, max: 6).isMaxed, isTrue);
      });

      test('returns false when base is below max', () {
        expect(base.isMaxed, isFalse);
      });
    });

    group('serialisation', () {
      test('toJson / fromJson roundtrip', () {
        final mod = StatModifier(
          sourceId: 's1',
          sourceName: 'Boost',
          value: 2,
          type: ModifierType.spell,
        );
        final attr = base.addModifier(mod);
        final restored = Attribute.fromJson(attr.toJson());
        expect(restored, equals(attr));
      });

      test('fromJson defaults base to 1 and max to 6', () {
        final attr = Attribute.fromJson({});
        expect(attr.base, 1);
        expect(attr.max, 6);
      });
    });
  });
}
