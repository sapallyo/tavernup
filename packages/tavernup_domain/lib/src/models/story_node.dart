import 'package:equatable/equatable.dart';

/// A node in the story structure — the universal building block for
/// campaigns, adventures, and chapters.
///
/// Story nodes form a recursive tree: a root node (no [parentId])
/// represents a campaign, its children are adventures, their children
/// are chapters, and so on. The depth is not limited by the model.
///
/// [characterIds] references the NPCs associated with this node.
/// Player characters are linked via [AdventureCharacter] in sessions.
///
/// [childIds] defines the ordered list of child node IDs. The order
/// of this list determines the narrative sequence.
class StoryNode extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;

  /// Identifies the RPG system this node was written for.
  ///
  /// Optional — system-agnostic nodes leave this null.
  /// Examples: `sr5`, `dsa4`, `swd6`.
  final String? systemKey;

  /// The parent node ID, or null if this is a root node.
  final String? parentId;

  /// Ordered list of child node IDs.
  ///
  /// The order of this list defines the narrative sequence.
  final List<String> childIds;

  /// IDs of characters (NPCs) associated with this node.
  final List<String> characterIds;

  final String createdBy;
  final DateTime createdAt;

  const StoryNode({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.systemKey,
    this.parentId,
    this.childIds = const [],
    this.characterIds = const [],
    required this.createdBy,
    required this.createdAt,
  });

  /// Returns true if this node is a root node (no parent).
  bool get isRoot => parentId == null;

  /// Returns true if this node has no children.
  bool get isLeaf => childIds.isEmpty;

  factory StoryNode.fromJson(Map<String, dynamic> json) {
    return StoryNode(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      systemKey: json['system_key'] as String?,
      parentId: json['parent_id'] as String?,
      childIds: List<String>.from(json['child_ids'] ?? []),
      characterIds: List<String>.from(json['character_ids'] ?? []),
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (description != null) 'description': description,
        if (imageUrl != null) 'image_url': imageUrl,
        if (systemKey != null) 'system_key': systemKey,
        if (parentId != null) 'parent_id': parentId,
        'child_ids': childIds,
        'character_ids': characterIds,
        'created_by': createdBy,
      };

  StoryNode copyWith({
    String? title,
    String? description,
    String? imageUrl,
    String? systemKey,
    String? parentId,
    List<String>? childIds,
    List<String>? characterIds,
    bool clearDescription = false,
    bool clearImageUrl = false,
    bool clearSystemKey = false,
    bool clearParentId = false,
  }) {
    return StoryNode(
      id: id,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      systemKey: clearSystemKey ? null : (systemKey ?? this.systemKey),
      parentId: clearParentId ? null : (parentId ?? this.parentId),
      childIds: childIds ?? this.childIds,
      characterIds: characterIds ?? this.characterIds,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        imageUrl,
        systemKey,
        parentId,
        childIds,
        characterIds,
        createdBy,
        createdAt,
      ];
}
