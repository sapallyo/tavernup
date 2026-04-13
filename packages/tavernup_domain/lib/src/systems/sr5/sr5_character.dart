import 'package:equatable/equatable.dart';
import '../../models/character.dart';
import 'attribute.dart';
import 'character_type.dart';
import 'character_type_data.dart';
import 'damage_track.dart';
import 'initiative.dart';
import 'resource_pool.dart';
import 'stat_modifier.dart';

/// A Shadowrun 5th Edition character with full SR5 stats.
///
/// Extends the system-agnostic [Character] with all SR5-specific
/// attributes, damage tracks, and derived values.
///
/// SR5-specific data is also serialised into [Character.customData]
/// so it can be stored and retrieved via the generic character
/// repository without the repository needing SR5 knowledge.
class Sr5Character extends Equatable {
  final Character base;

  // Physical attributes
  final Attribute constitution;
  final Attribute agility;
  final Attribute reaction;
  final Attribute strength;

  // Mental attributes
  final Attribute willpower;
  final Attribute logic;
  final Attribute intuition;
  final Attribute charisma;

  // Special attributes (optional)
  final Attribute? magic;
  final Attribute? resonance;

  /// Essence — starts at 6.0, reduced by cyberware/bioware.
  final double essence;

  final Initiative initiative;
  final Sr5CharacterType characterType;
  final Sr5CharacterTypeData typeData;

  final DamageTrack physicalTrack;
  final DamageTrack stunTrack;
  final ResourcePool edgePool;

  const Sr5Character({
    required this.base,
    required this.constitution,
    required this.agility,
    required this.reaction,
    required this.strength,
    required this.willpower,
    required this.logic,
    required this.intuition,
    required this.charisma,
    this.magic,
    this.resonance,
    this.essence = 6.0,
    this.initiative = const Initiative(),
    required this.characterType,
    required this.typeData,
    required this.physicalTrack,
    required this.stunTrack,
    required this.edgePool,
  });

  // ── Derived values ───────────────────────────────────────────────────────────

  /// Calculated maximum physical monitor boxes.
  ///
  /// SR5 formula: 8 + ceil(CON / 2)
  int get calculatedPhysicalMax => 8 + (constitution.effective / 2).ceil();

  /// Calculated maximum stun monitor boxes.
  ///
  /// SR5 formula: 8 + ceil(WIL / 2)
  int get calculatedStunMax => 8 + (willpower.effective / 2).ceil();

  /// Initiative base value (REA + INT + modifiers).
  ///
  /// Dice are rolled at the table and added to this value.
  int get initiativeBase =>
      initiative.effectiveBase(reaction.effective + intuition.effective);

  /// Combined wound modifier from both damage tracks.
  int get totalWoundModifier =>
      physicalTrack.woundModifier + stunTrack.woundModifier;

  /// Returns true if either damage track is full.
  bool get isIncapacitated =>
      physicalTrack.isIncapacitated || stunTrack.isIncapacitated;

  /// Returns true if this character is an awakened mage.
  bool get isMage {
    final md = typeData is MetatypeData ? typeData as MetatypeData : null;
    return magic != null && md?.tradition != null && !(md?.isAdept ?? false);
  }

  /// Returns true if this character is an adept.
  bool get isAdept {
    final md = typeData is MetatypeData ? typeData as MetatypeData : null;
    return magic != null && (md?.isAdept ?? false);
  }

  /// Returns true if this character is a technomancer.
  bool get isTechnomancer {
    final md = typeData is MetatypeData ? typeData as MetatypeData : null;
    return resonance != null && (md?.isTechnomancer ?? false);
  }

  // ── Modifier helpers ─────────────────────────────────────────────────────────

  /// Returns a new character with the given modifier removed from all attributes.
  ///
  /// Use this when a spell, power or other effect expires.
  Sr5Character removeModifierFromAll(String sourceId) {
    return copyWith(
      constitution: constitution.removeModifier(sourceId),
      agility: agility.removeModifier(sourceId),
      reaction: reaction.removeModifier(sourceId),
      strength: strength.removeModifier(sourceId),
      willpower: willpower.removeModifier(sourceId),
      logic: logic.removeModifier(sourceId),
      intuition: intuition.removeModifier(sourceId),
      charisma: charisma.removeModifier(sourceId),
      magic: magic?.removeModifier(sourceId),
      resonance: resonance?.removeModifier(sourceId),
      initiative: initiative.removeModifier(sourceId),
    );
  }

  /// Returns a new character with a wound modifier applied to all attributes.
  Sr5Character applyWoundModifier(int value) {
    const sourceId = 'wound-modifier';
    final mod = StatModifier(
      sourceId: sourceId,
      sourceName: 'Wundabzug',
      value: value,
      type: ModifierType.wound,
    );
    return copyWith(
      constitution: constitution.addModifier(mod),
      agility: agility.addModifier(mod),
      reaction: reaction.addModifier(mod),
      strength: strength.addModifier(mod),
      willpower: willpower.addModifier(mod),
      logic: logic.addModifier(mod),
      intuition: intuition.addModifier(mod),
      charisma: charisma.addModifier(mod),
      initiative: initiative.addModifier(mod),
    );
  }

  // ── Serialisation ────────────────────────────────────────────────────────────

  /// Creates an [Sr5Character] from a [Character] by parsing [Character.customData].
  factory Sr5Character.fromCharacter(Character character) {
    final json = character.customData;
    final type = Sr5CharacterType.fromString(
      json['character_type'] as String? ?? 'human',
    );

    Attribute parseAttr(String key, {int defaultMax = 6}) {
      final raw = json[key];
      if (raw is Map<String, dynamic>) return Attribute.fromJson(raw);
      return Attribute(base: (raw as int?) ?? 1, max: defaultMax);
    }

    final con = parseAttr('constitution');
    final wil = parseAttr('willpower');
    final edgeMax = json['edge_max'] as int? ?? 3;
    final edgeCurrent = json['edge_current'] as int? ?? edgeMax;

    final physTrack = json['physical_track'] != null
        ? DamageTrack.fromJson(json['physical_track'] as Map<String, dynamic>)
        : DamageTrack.physical(con.effective);

    final stunTrack = json['stun_track'] != null
        ? DamageTrack.fromJson(json['stun_track'] as Map<String, dynamic>)
        : DamageTrack.stun(wil.effective);

    return Sr5Character(
      base: character,
      constitution: con,
      agility: parseAttr('agility'),
      reaction: parseAttr('reaction'),
      strength: parseAttr('strength'),
      willpower: wil,
      logic: parseAttr('logic'),
      intuition: parseAttr('intuition'),
      charisma: parseAttr('charisma'),
      magic: json['magic'] != null
          ? (json['magic'] is Map
              ? Attribute.fromJson(json['magic'] as Map<String, dynamic>)
              : Attribute(base: json['magic'] as int? ?? 0, max: 6))
          : null,
      resonance: json['resonance'] != null
          ? (json['resonance'] is Map
              ? Attribute.fromJson(json['resonance'] as Map<String, dynamic>)
              : Attribute(base: json['resonance'] as int? ?? 0, max: 6))
          : null,
      essence: (json['essence'] as num?)?.toDouble() ?? 6.0,
      initiative: json['initiative'] != null
          ? Initiative.fromJson(json['initiative'] as Map<String, dynamic>)
          : const Initiative(),
      characterType: type,
      typeData: Sr5CharacterTypeData.fromJson(
        type,
        json['type_data'] as Map<String, dynamic>? ?? {},
      ),
      physicalTrack: physTrack,
      stunTrack: stunTrack,
      edgePool: ResourcePool(max: edgeMax, current: edgeCurrent),
    );
  }

  /// Serialises SR5 data into a map suitable for [Character.customData].
  Map<String, dynamic> toCustomData() => {
        'character_type': characterType.value,
        'constitution': constitution.toJson(),
        'agility': agility.toJson(),
        'reaction': reaction.toJson(),
        'strength': strength.toJson(),
        'willpower': willpower.toJson(),
        'logic': logic.toJson(),
        'intuition': intuition.toJson(),
        'charisma': charisma.toJson(),
        if (magic != null) 'magic': magic!.toJson(),
        if (resonance != null) 'resonance': resonance!.toJson(),
        'essence': essence,
        'initiative': initiative.toJson(),
        'edge_max': edgePool.max,
        'edge_current': edgePool.current,
        'physical_track': physicalTrack.toJson(),
        'stun_track': stunTrack.toJson(),
        'type_data': typeData.toJson(),
      };

  /// Returns a [Character] with [customData] updated from this Sr5Character.
  Character toCharacter() => base.copyWith(customData: toCustomData());

  Sr5Character copyWith({
    Character? base,
    Attribute? constitution,
    Attribute? agility,
    Attribute? reaction,
    Attribute? strength,
    Attribute? willpower,
    Attribute? logic,
    Attribute? intuition,
    Attribute? charisma,
    Attribute? magic,
    bool clearMagic = false,
    Attribute? resonance,
    bool clearResonance = false,
    double? essence,
    Initiative? initiative,
    Sr5CharacterType? characterType,
    Sr5CharacterTypeData? typeData,
    DamageTrack? physicalTrack,
    DamageTrack? stunTrack,
    ResourcePool? edgePool,
  }) {
    return Sr5Character(
      base: base ?? this.base,
      constitution: constitution ?? this.constitution,
      agility: agility ?? this.agility,
      reaction: reaction ?? this.reaction,
      strength: strength ?? this.strength,
      willpower: willpower ?? this.willpower,
      logic: logic ?? this.logic,
      intuition: intuition ?? this.intuition,
      charisma: charisma ?? this.charisma,
      magic: clearMagic ? null : (magic ?? this.magic),
      resonance: clearResonance ? null : (resonance ?? this.resonance),
      essence: essence ?? this.essence,
      initiative: initiative ?? this.initiative,
      characterType: characterType ?? this.characterType,
      typeData: typeData ?? this.typeData,
      physicalTrack: physicalTrack ?? this.physicalTrack,
      stunTrack: stunTrack ?? this.stunTrack,
      edgePool: edgePool ?? this.edgePool,
    );
  }

  @override
  List<Object?> get props => [
        base,
        constitution,
        agility,
        reaction,
        strength,
        willpower,
        logic,
        intuition,
        charisma,
        magic,
        resonance,
        essence,
        initiative,
        characterType,
        typeData,
        physicalTrack,
        stunTrack,
        edgePool,
      ];
}
