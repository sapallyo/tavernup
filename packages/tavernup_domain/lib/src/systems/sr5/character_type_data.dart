import 'character_type.dart';
import 'skill.dart';

/// Base class for type-specific character data in SR5.
///
/// Each [Sr5CharacterType] has a different data structure.
/// The sealed class hierarchy ensures exhaustive handling
/// in switch expressions throughout the codebase.
///
/// Parsing is dispatched by [fromJson] based on the character type.
sealed class Sr5CharacterTypeData {
  const Sr5CharacterTypeData();

  Map<String, dynamic> toJson();

  /// Parses type-specific data for the given [type].
  static Sr5CharacterTypeData fromJson(
    Sr5CharacterType type,
    Map<String, dynamic> json,
  ) {
    return switch (type) {
      Sr5CharacterType.human ||
      Sr5CharacterType.elf ||
      Sr5CharacterType.dwarf ||
      Sr5CharacterType.ork ||
      Sr5CharacterType.troll =>
        MetatypeData.fromJson(json),
      Sr5CharacterType.spirit => SpiritData.fromJson(json),
      Sr5CharacterType.critter => CritterData.fromJson(json),
      Sr5CharacterType.ai => AiData.fromJson(json),
    };
  }
}

/// Type data for metatype characters (human, elf, dwarf, ork, troll).
///
/// Carries magical and resonance attributes, learned skills,
/// and flags for awakened/emerged archetypes.
class MetatypeData extends Sr5CharacterTypeData {
  /// The magical tradition (e.g. hermetic, shamanic) if awakened.
  final String? tradition;
  final bool isAdept;
  final bool isTechnomancer;
  final List<String> spells;
  final List<String> adeptPowers;
  final List<String> complexForms;
  final List<Skill> skills;

  const MetatypeData({
    this.tradition,
    this.isAdept = false,
    this.isTechnomancer = false,
    this.spells = const [],
    this.adeptPowers = const [],
    this.complexForms = const [],
    this.skills = const [],
  });

  factory MetatypeData.fromJson(Map<String, dynamic> json) {
    return MetatypeData(
      tradition: json['tradition'] as String?,
      isAdept: json['is_adept'] as bool? ?? false,
      isTechnomancer: json['is_technomancer'] as bool? ?? false,
      spells: List<String>.from(json['spells'] ?? []),
      adeptPowers: List<String>.from(json['adept_powers'] ?? []),
      complexForms: List<String>.from(json['complex_forms'] ?? []),
      skills: (json['skills'] as List? ?? [])
          .map((s) => Skill.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        if (tradition != null) 'tradition': tradition,
        'is_adept': isAdept,
        'is_technomancer': isTechnomancer,
        'spells': spells,
        'adept_powers': adeptPowers,
        'complex_forms': complexForms,
        'skills': skills.map((s) => s.toJson()).toList(),
      };
}

/// Type data for spirit characters.
///
/// Spirits have a force level ([forceLevel]) rather than
/// individual attributes, and a set of spirit powers.
class SpiritData extends Sr5CharacterTypeData {
  /// The force (Kraftstufe) of this spirit.
  final int forceLevel;
  final String spiritType;
  final List<String> powers;
  final bool isMaterialized;

  const SpiritData({
    required this.forceLevel,
    required this.spiritType,
    this.powers = const [],
    this.isMaterialized = false,
  });

  factory SpiritData.fromJson(Map<String, dynamic> json) {
    return SpiritData(
      forceLevel: json['kraftstufe'] as int? ?? 1,
      spiritType: json['spirit_type'] as String? ?? 'unknown',
      powers: List<String>.from(json['powers'] ?? []),
      isMaterialized: json['is_materialized'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'kraftstufe': forceLevel,
        'spirit_type': spiritType,
        'powers': powers,
        'is_materialized': isMaterialized,
      };
}

/// Type data for critter characters.
class CritterData extends Sr5CharacterTypeData {
  final String critterType;
  final List<String> powers;

  const CritterData({
    required this.critterType,
    this.powers = const [],
  });

  factory CritterData.fromJson(Map<String, dynamic> json) {
    return CritterData(
      critterType: json['critter_type'] as String? ?? 'unknown',
      powers: List<String>.from(json['powers'] ?? []),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'critter_type': critterType,
        'powers': powers,
      };
}

/// Type data for AI characters.
class AiData extends Sr5CharacterTypeData {
  /// The AI's rating, analogous to force for spirits.
  final int rating;
  final List<String> programs;

  const AiData({
    required this.rating,
    this.programs = const [],
  });

  factory AiData.fromJson(Map<String, dynamic> json) {
    return AiData(
      rating: json['rating'] as int? ?? 1,
      programs: List<String>.from(json['programs'] ?? []),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'rating': rating,
        'programs': programs,
      };
}
