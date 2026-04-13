import 'package:equatable/equatable.dart';

/// The category a SR5 skill belongs to.
///
/// Used for grouping skills in the character sheet UI
/// and for filtering skill lists.
enum SkillCategory {
  combat,
  physical,
  social,
  technical,
  knowledge,
  magic,
  language;

  /// Human-readable display name for this category.
  String get displayName => switch (this) {
        SkillCategory.combat => 'Kampf',
        SkillCategory.physical => 'Körper',
        SkillCategory.social => 'Sozial',
        SkillCategory.technical => 'Technik',
        SkillCategory.knowledge => 'Wissen',
        SkillCategory.magic => 'Magie',
        SkillCategory.language => 'Sprache',
      };

  /// Parses a category from its string representation.
  static SkillCategory fromString(String value) {
    return SkillCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SkillCategory.combat,
    );
  }
}

/// A SR5 skill with a rating and an optional specialisation.
///
/// The dice pool for a skill check is calculated externally
/// as skill rating + linked attribute — it is not stored here.
///
/// [specialisation] grants a +2 bonus when the check falls
/// within the specialisation's scope.
class Skill extends Equatable {
  final String name;

  /// The skill rating (Stufe), typically 1–12.
  final int rating;

  /// Optional specialisation granting a +2 bonus in its scope.
  final String? specialisation;

  final SkillCategory category;

  const Skill({
    required this.name,
    required this.rating,
    this.specialisation,
    required this.category,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      name: json['name'] as String,
      rating: json['stufe'] as int? ?? 1,
      specialisation: json['spezialisierung'] as String?,
      category: SkillCategory.fromString(
        json['kategorie'] as String? ?? 'combat',
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'stufe': rating,
        if (specialisation != null) 'spezialisierung': specialisation,
        'kategorie': category.name,
      };

  Skill copyWith({
    String? name,
    int? rating,
    String? specialisation,
    SkillCategory? category,
  }) {
    return Skill(
      name: name ?? this.name,
      rating: rating ?? this.rating,
      specialisation: specialisation ?? this.specialisation,
      category: category ?? this.category,
    );
  }

  @override
  List<Object?> get props => [name, rating, specialisation, category];
}
