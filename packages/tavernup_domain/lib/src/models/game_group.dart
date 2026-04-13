import 'package:equatable/equatable.dart';

/// A game group represents a circle of players who play together.
///
/// A group has a [ruleset] that identifies the RPG system being played
/// (e.g. `sr5`, `dsa4`, `swd6`). This is intentionally a plain string
/// rather than an enum — the platform is system-agnostic and new
/// rulesets can be added without code changes.
///
/// A group can have multiple campaigns and adventures, and its members
/// each hold a [GameGroupRole] defined in their [GameGroupMembership].
class GameGroup extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String createdBy;
  final String ruleset;
  final DateTime createdAt;
  final String? imageUrl;

  const GameGroup({
    required this.id,
    required this.name,
    this.description,
    required this.createdBy,
    this.ruleset = 'generic',
    required this.createdAt,
    this.imageUrl,
  });

  factory GameGroup.fromJson(Map<String, dynamic> json) {
    return GameGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdBy: json['created_by'] as String,
      ruleset: json['ruleset'] as String? ?? 'generic',
      createdAt: DateTime.parse(json['created_at'] as String),
      imageUrl: json['image_url'] as String?,
    );
  }

  GameGroup copyWith({
    String? name,
    String? description,
    String? ruleset,
    String? imageUrl,
    bool clearImage = false,
    bool clearDescription = false,
  }) {
    return GameGroup(
      id: id,
      name: name ?? this.name,
      description: clearDescription ? null : description ?? this.description,
      createdBy: createdBy,
      ruleset: ruleset ?? this.ruleset,
      createdAt: createdAt,
      imageUrl: clearImage ? null : imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        'created_by': createdBy,
        if (imageUrl != null) 'image_url': imageUrl,
        'ruleset': ruleset,
      };

  @override
  List<Object?> get props =>
      [id, name, description, createdBy, ruleset, createdAt, imageUrl];
}
