import 'package:equatable/equatable.dart';
import 'adventure_character.dart';

/// A single play session within a game group.
///
/// A session is the central binding element of the platform — it
/// connects a game group, its players (via [AdventureCharacter]),
/// and the story content being played (via [instanceIds]).
///
/// [instanceIds] is an ordered list of [StoryNodeInstance] IDs
/// representing the story content covered in this session.
/// A session can cover multiple instances — for example when a
/// group finishes one chapter and starts the next in the same evening.
///
/// [participants] lists the player/character pairings active in
/// this session.
class Session extends Equatable {
  final String id;

  /// Ordered list of [StoryNodeInstance] IDs covered in this session.
  final List<String> instanceIds;

  /// Player/character pairings active in this session.
  final List<AdventureCharacter> participants;

  final String createdBy;
  final DateTime createdAt;

  const Session({
    required this.id,
    this.instanceIds = const [],
    this.participants = const [],
    required this.createdBy,
    required this.createdAt,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      instanceIds: List<String>.from(json['instance_ids'] ?? []),
      participants: (json['participants'] as List? ?? [])
          .map((p) => AdventureCharacter.fromJson(p as Map<String, dynamic>))
          .toList(),
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'instance_ids': instanceIds,
        'participants': participants.map((p) => p.toJson()).toList(),
        'created_by': createdBy,
      };

  Session copyWith({
    List<String>? instanceIds,
    List<AdventureCharacter>? participants,
  }) {
    return Session(
      id: id,
      instanceIds: instanceIds ?? this.instanceIds,
      participants: participants ?? this.participants,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, instanceIds, participants, createdBy, createdAt];
}
