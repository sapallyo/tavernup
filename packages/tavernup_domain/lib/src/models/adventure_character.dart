import 'package:equatable/equatable.dart';

/// The role a character takes on within a session.
///
/// Can differ from the character's default role — a game master might
/// hand control of an NPC to a player for a specific session.
enum CharacterRoleOverride {
  pc,
  npc;

  /// Parses a role override from its string representation.
  static CharacterRoleOverride fromString(String value) {
    return CharacterRoleOverride.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CharacterRoleOverride.npc,
    );
  }
}

/// A pairing of a [User] and a [Character] within a [Session].
///
/// Represents who plays which character during a specific session.
/// The [userId] is the player controlling the character, [characterId]
/// is the character being played.
///
/// [roleOverride] optionally overrides the character's default role
/// for this specific session — for example when a GM hands an NPC
/// to a player temporarily.
class AdventureCharacter extends Equatable {
  final String id;
  final String userId;
  final String characterId;
  final CharacterRoleOverride? roleOverride;
  final DateTime addedAt;

  const AdventureCharacter({
    required this.id,
    required this.userId,
    required this.characterId,
    this.roleOverride,
    required this.addedAt,
  });

  factory AdventureCharacter.fromJson(Map<String, dynamic> json) {
    return AdventureCharacter(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      characterId: json['character_id'] as String,
      roleOverride: json['role_override'] != null
          ? CharacterRoleOverride.fromString(json['role_override'] as String)
          : null,
      addedAt: json['added_at'] != null
          ? DateTime.parse(json['added_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'character_id': characterId,
        if (roleOverride != null) 'role_override': roleOverride!.name,
        'added_at': addedAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, userId, characterId, roleOverride, addedAt];
}
