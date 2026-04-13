import 'package:equatable/equatable.dart';
import 'adventure_character.dart';

/// A character owned by a user, playable across adventures.
///
/// This is the system-agnostic representation of a character.
/// It carries only the data that is meaningful regardless of
/// the RPG system being played.
///
/// System-specific data (attributes, skills, damage tracks etc.)
/// is stored in [customData] as raw JSON and parsed by the
/// appropriate system layer — for example `Sr5Character` for
/// Shadowrun 5th Edition.
///
/// Visibility is controlled via [visibleFor]: an empty list means
/// the character is only visible to its [ownerId]. Add user IDs
/// to grant read access to other players.
class Character extends Equatable {
  final String id;
  final String ownerId;
  final String name;

  /// Identifies the RPG system this character belongs to.
  ///
  /// Used to determine which system layer should parse [customData].
  /// Examples: `sr5`, `dsa4`, `swd6`, `splittermond`.
  final String systemKey;

  /// The character's default role when added to an adventure.
  ///
  /// Can be overridden per adventure via [CharacterRoleOverride].
  final CharacterRoleOverride defaultRole;

  /// Raw system-specific data for this character.
  ///
  /// The structure of this map is defined by the system layer
  /// identified by [systemKey]. The domain layer treats it as opaque.
  final Map<String, dynamic> customData;

  /// User IDs that are allowed to view this character.
  ///
  /// An empty list means only the [ownerId] can see the character.
  final List<String> visibleFor;

  final String? imageUrl;

  const Character({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.systemKey,
    this.defaultRole = CharacterRoleOverride.npc,
    this.customData = const {},
    this.visibleFor = const [],
    this.imageUrl,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      systemKey: json['system_key'] as String? ?? 'generic',
      defaultRole: CharacterRoleOverride.fromString(
        json['default_role'] as String? ?? 'npc',
      ),
      customData: json['custom_data'] as Map<String, dynamic>? ?? {},
      visibleFor: List<String>.from(json['visible_for'] ?? []),
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'name': name,
        'system_key': systemKey,
        'default_role': defaultRole.name,
        'custom_data': customData,
        'visible_for': visibleFor,
        if (imageUrl != null) 'image_url': imageUrl,
      };

  Character copyWith({
    String? name,
    String? systemKey,
    CharacterRoleOverride? defaultRole,
    Map<String, dynamic>? customData,
    List<String>? visibleFor,
    String? imageUrl,
    bool clearImage = false,
  }) {
    return Character(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      systemKey: systemKey ?? this.systemKey,
      defaultRole: defaultRole ?? this.defaultRole,
      customData: customData ?? this.customData,
      visibleFor: visibleFor ?? this.visibleFor,
      imageUrl: clearImage ? null : (imageUrl ?? this.imageUrl),
    );
  }

  @override
  List<Object?> get props => [
        id,
        ownerId,
        name,
        systemKey,
        defaultRole,
        customData,
        visibleFor,
        imageUrl,
      ];
}
