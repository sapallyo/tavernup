/// The metatype or entity type of a SR5 character.
///
/// Metatypes (human through troll) are playable characters
/// with standard SR5 attributes. The remaining types have
/// different stat structures handled by their respective
/// [CharacterTypeData] subclasses.
enum Sr5CharacterType {
  human,
  elf,
  dwarf,
  ork,
  troll,
  spirit,
  critter,
  ai;

  /// Human-readable display name for this type.
  String get displayName => switch (this) {
        Sr5CharacterType.human => 'Mensch',
        Sr5CharacterType.elf => 'Elf',
        Sr5CharacterType.dwarf => 'Zwerg',
        Sr5CharacterType.ork => 'Ork',
        Sr5CharacterType.troll => 'Troll',
        Sr5CharacterType.spirit => 'Geist',
        Sr5CharacterType.critter => 'Critter',
        Sr5CharacterType.ai => 'KI',
      };

  String get value => name;

  /// Parses a type from its string representation.
  ///
  /// Returns [Sr5CharacterType.human] as a safe default.
  static Sr5CharacterType fromString(String value) {
    return Sr5CharacterType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => Sr5CharacterType.human,
    );
  }
}
