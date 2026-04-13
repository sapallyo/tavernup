import 'package:equatable/equatable.dart';

/// Defines whether a character participates as a player character
/// or non-player character within a specific adventure.
///
/// This can differ from the character's default role — a GM might
/// temporarily hand control of an NPC to a player, for example.
enum CharacterRoleOverride {
  pc,
  npc;

  /// Parses a role override from its string representation.
  ///
  /// Returns [CharacterRoleOverride.npc] as a safe default if the
  /// value is not recognised.
  static CharacterRoleOverride fromString(String value) {
    return CharacterRoleOverride.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CharacterRoleOverride.npc,
    );
  }
}

/// Represents a character's participation in a specific adventure.
///
/// Links a character to an adventure and records who controls it
/// during that adventure. Control can be transferred from the
/// [originalController] to another user ([controlledBy]) with
/// the consent of the original controller ([transferConsent]).
class AdventureCharacter extends Equatable {
  final String id;
  final String adventureId;
  final String characterId;
  final CharacterRoleOverride? roleOverride;
  final String controlledBy;
  final String originalController;
  final bool transferConsent;
  final DateTime addedAt;

  const AdventureCharacter({
    required this.id,
    required this.adventureId,
    required this.characterId,
    this.roleOverride,
    required this.controlledBy,
    required this.originalController,
    this.transferConsent = false,
    required this.addedAt,
  });

  factory AdventureCharacter.fromJson(Map<String, dynamic> json) {
    return AdventureCharacter(
      id: json['id'] as String,
      adventureId: json['adventure_id'] as String,
      characterId: json['character_id'] as String,
      roleOverride: json['role_override'] != null
          ? CharacterRoleOverride.fromString(json['role_override'] as String)
          : null,
      controlledBy: json['controlled_by'] as String,
      originalController: json['original_controller'] as String,
      transferConsent: json['transfer_consent'] as bool? ?? false,
      addedAt: DateTime.parse(json['added_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'adventure_id': adventureId,
        'character_id': characterId,
        if (roleOverride != null) 'role_override': roleOverride!.name,
        'controlled_by': controlledBy,
        'original_controller': originalController,
        'transfer_consent': transferConsent,
      };

  @override
  List<Object?> get props => [
        id,
        adventureId,
        characterId,
        roleOverride,
        controlledBy,
        originalController,
        transferConsent,
        addedAt,
      ];
}
