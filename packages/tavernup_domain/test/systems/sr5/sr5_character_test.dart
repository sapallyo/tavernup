import 'package:test/test.dart';
import 'package:tavernup_domain/tavernup_domain.dart';

// Helper to build a minimal Sr5Character for testing
Sr5Character buildCharacter({
  Attribute? constitution,
  Attribute? willpower,
  Attribute? magic,
  Attribute? resonance,
  String? tradition,
  bool isAdept = false,
  bool isTechnomancer = false,
  DamageTrack? physicalTrack,
  DamageTrack? stunTrack,
  Initiative? initiative,
  Attribute? reaction,
  Attribute? intuition,
}) {
  final con = constitution ?? Attribute(base: 4, max: 6);
  final wil = willpower ?? Attribute(base: 4, max: 6);
  final rea = reaction ?? Attribute(base: 4, max: 6);
  final int_ = intuition ?? Attribute(base: 4, max: 6);

  return Sr5Character(
    base: Character(
      id: 'char-1',
      ownerId: 'user-1',
      name: 'Test Character',
      systemKey: 'sr5',
    ),
    constitution: con,
    agility: Attribute(base: 4, max: 6),
    reaction: rea,
    strength: Attribute(base: 3, max: 6),
    willpower: wil,
    logic: Attribute(base: 4, max: 6),
    intuition: int_,
    charisma: Attribute(base: 3, max: 6),
    magic: magic,
    resonance: resonance,
    initiative: initiative ?? const Initiative(),
    characterType: Sr5CharacterType.human,
    typeData: MetatypeData(
      tradition: tradition,
      isAdept: isAdept,
      isTechnomancer: isTechnomancer,
    ),
    physicalTrack: physicalTrack ?? DamageTrack.physical(con.effective),
    stunTrack: stunTrack ?? DamageTrack.stun(wil.effective),
    edgePool: ResourcePool(max: 3, current: 3),
  );
}

void main() {
  group('Sr5Character', () {
    group('calculatedPhysicalMax', () {
      test('SR5 formula: 8 + ceil(CON/2)', () {
        expect(
            buildCharacter(constitution: Attribute(base: 4, max: 6))
                .calculatedPhysicalMax,
            10);
        expect(
            buildCharacter(constitution: Attribute(base: 3, max: 6))
                .calculatedPhysicalMax,
            10);
        expect(
            buildCharacter(constitution: Attribute(base: 5, max: 6))
                .calculatedPhysicalMax,
            11);
        expect(
            buildCharacter(constitution: Attribute(base: 6, max: 6))
                .calculatedPhysicalMax,
            11);
      });
    });

    group('calculatedStunMax', () {
      test('SR5 formula: 8 + ceil(WIL/2)', () {
        expect(
            buildCharacter(willpower: Attribute(base: 4, max: 6))
                .calculatedStunMax,
            10);
        expect(
            buildCharacter(willpower: Attribute(base: 5, max: 6))
                .calculatedStunMax,
            11);
      });
    });

    group('initiativeBase', () {
      test('equals REA + INT + modifiers', () {
        final char = buildCharacter(
          reaction: Attribute(base: 4, max: 6),
          intuition: Attribute(base: 3, max: 6),
        );
        expect(char.initiativeBase, 7);
      });

      test('includes initiative modifiers', () {
        final mod = StatModifier(
          sourceId: 'wired',
          sourceName: 'Wired Reflexes',
          value: 2,
          type: ModifierType.cyberware,
        );
        final char = buildCharacter(
          reaction: Attribute(base: 4, max: 6),
          intuition: Attribute(base: 3, max: 6),
          initiative: Initiative(diceCount: 2).addModifier(mod),
        );
        expect(char.initiativeBase, 9);
      });
    });

    group('totalWoundModifier', () {
      test('no damage — zero modifier', () {
        expect(buildCharacter().totalWoundModifier, 0);
      });

      test('sums physical and stun modifiers', () {
        final char = buildCharacter(
          physicalTrack: DamageTrack(max: 10, current: 6),
          stunTrack: DamageTrack(max: 10, current: 3),
        );
        expect(char.totalWoundModifier, -3);
      });
    });

    group('isIncapacitated', () {
      test('not incapacitated with partial damage', () {
        expect(buildCharacter().isIncapacitated, isFalse);
      });

      test('incapacitated when physical track full', () {
        final char = buildCharacter(
          physicalTrack: DamageTrack(max: 10, current: 10),
        );
        expect(char.isIncapacitated, isTrue);
      });

      test('incapacitated when stun track full', () {
        final char = buildCharacter(
          stunTrack: DamageTrack(max: 10, current: 10),
        );
        expect(char.isIncapacitated, isTrue);
      });
    });

    group('isMage / isAdept / isTechnomancer', () {
      test('mage has magic and tradition, not adept', () {
        final char = buildCharacter(
          magic: Attribute(base: 5, max: 6),
          tradition: 'hermetic',
        );
        expect(char.isMage, isTrue);
        expect(char.isAdept, isFalse);
        expect(char.isTechnomancer, isFalse);
      });

      test('adept has magic but no tradition', () {
        final char = buildCharacter(
          magic: Attribute(base: 5, max: 6),
          isAdept: true,
        );
        expect(char.isAdept, isTrue);
        expect(char.isMage, isFalse);
      });

      test('technomancer has resonance', () {
        final char = buildCharacter(
          resonance: Attribute(base: 5, max: 6),
          isTechnomancer: true,
        );
        expect(char.isTechnomancer, isTrue);
        expect(char.isMage, isFalse);
      });

      test('mundane has neither magic nor resonance', () {
        final char = buildCharacter();
        expect(char.isMage, isFalse);
        expect(char.isAdept, isFalse);
        expect(char.isTechnomancer, isFalse);
      });
    });

    group('removeModifierFromAll', () {
      test('removes modifier from all attributes', () {
        final mod = StatModifier(
          sourceId: 'spell-1',
          sourceName: 'Boost',
          value: 2,
          type: ModifierType.spell,
        );
        final char = buildCharacter(
          constitution: Attribute(base: 4, max: 6).addModifier(mod),
          willpower: Attribute(base: 4, max: 6).addModifier(mod),
        );
        final cleaned = char.removeModifierFromAll('spell-1');
        expect(cleaned.constitution.modifiers, isEmpty);
        expect(cleaned.willpower.modifiers, isEmpty);
      });
    });

    group('applyWoundModifier', () {
      test('applies wound modifier to all attributes', () {
        final char = buildCharacter();
        final wounded = char.applyWoundModifier(-2);
        expect(wounded.constitution.modifiers.length, 1);
        expect(wounded.constitution.modifiers.first.type, ModifierType.wound);
        expect(wounded.constitution.modifiers.first.value, -2);
        expect(wounded.agility.modifiers.length, 1);
        expect(wounded.charisma.modifiers.length, 1);
      });

      test('wound modifier affects effective values', () {
        final char = buildCharacter(
          constitution: Attribute(base: 4, max: 6),
        );
        final wounded = char.applyWoundModifier(-2);
        expect(wounded.constitution.effective, 2);
      });
    });

    group('toCharacter / fromCharacter roundtrip', () {
      test('serialises and deserialises SR5 data via customData', () {
        final char = buildCharacter(
          constitution: Attribute(base: 5, max: 6),
          magic: Attribute(base: 4, max: 6),
          tradition: 'hermetic',
        );
        final baseChar = char.toCharacter();
        final restored = Sr5Character.fromCharacter(baseChar);
        expect(restored.constitution.base, 5);
        expect(restored.magic?.base, 4);
        expect(restored.isMage, isTrue);
      });
    });
  });
}
