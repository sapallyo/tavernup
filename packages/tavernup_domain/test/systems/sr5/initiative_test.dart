import 'package:test/test.dart';
import 'package:tavernup_domain/tavernup_domain.dart';

void main() {
  group('Initiative', () {
    const base = Initiative(diceCount: 1);

    group('effectiveBase', () {
      test('no modifiers — equals rea + int', () {
        expect(base.effectiveBase(8), 8);
      });

      test('positive modifier increases base', () {
        final mod = StatModifier(
          sourceId: 'wired-1',
          sourceName: 'Wired Reflexes',
          value: 2,
          type: ModifierType.cyberware,
        );
        expect(base.addModifier(mod).effectiveBase(8), 10);
      });

      test('negative modifier decreases base', () {
        final mod = StatModifier(
          sourceId: 'w1',
          sourceName: 'Wunde',
          value: -2,
          type: ModifierType.wound,
        );
        expect(base.addModifier(mod).effectiveBase(8), 6);
      });
    });

    group('totalModifier', () {
      test('no modifiers — zero', () {
        expect(base.totalModifier, 0);
      });

      test('sums all modifier values', () {
        final mod1 = StatModifier(
          sourceId: 's1',
          sourceName: 'A',
          value: 2,
          type: ModifierType.cyberware,
        );
        final mod2 = StatModifier(
          sourceId: 's2',
          sourceName: 'B',
          value: -1,
          type: ModifierType.wound,
        );
        expect(base.addModifier(mod1).addModifier(mod2).totalModifier, 1);
      });
    });

    group('addModifier', () {
      test('replaces existing modifier with same sourceId', () {
        final mod1 = StatModifier(
          sourceId: 's1',
          sourceName: 'A',
          value: 1,
          type: ModifierType.cyberware,
        );
        final mod2 = StatModifier(
          sourceId: 's1',
          sourceName: 'A',
          value: 3,
          type: ModifierType.cyberware,
        );
        final init = base.addModifier(mod1).addModifier(mod2);
        expect(init.modifiers.length, 1);
        expect(init.totalModifier, 3);
      });
    });

    group('removeModifier', () {
      test('removes modifier by sourceId', () {
        final mod = StatModifier(
          sourceId: 's1',
          sourceName: 'A',
          value: 2,
          type: ModifierType.cyberware,
        );
        final init = base.addModifier(mod).removeModifier('s1');
        expect(init.modifiers, isEmpty);
      });
    });

    group('withDiceCount', () {
      test('updates dice count', () {
        expect(base.withDiceCount(3).diceCount, 3);
      });

      test('clamps to minimum 1', () {
        expect(base.withDiceCount(0).diceCount, 1);
      });

      test('clamps to maximum 5', () {
        expect(base.withDiceCount(10).diceCount, 5);
      });
    });

    group('clearModifiers', () {
      test('removes all modifiers', () {
        final mod = StatModifier(
          sourceId: 's1',
          sourceName: 'A',
          value: 2,
          type: ModifierType.cyberware,
        );
        expect(base.addModifier(mod).clearModifiers().modifiers, isEmpty);
      });
    });

    group('serialisation', () {
      test('toJson / fromJson roundtrip', () {
        final mod = StatModifier(
          sourceId: 's1',
          sourceName: 'Wired Reflexes',
          value: 2,
          type: ModifierType.cyberware,
        );
        final init = Initiative(diceCount: 3).addModifier(mod);
        final restored = Initiative.fromJson(init.toJson());
        expect(restored.diceCount, 3);
        expect(restored.modifiers.length, 1);
        expect(restored.totalModifier, 2);
      });

      test('fromJson defaults diceCount to 1', () {
        expect(Initiative.fromJson({}).diceCount, 1);
      });
    });
  });
}
