import 'package:equatable/equatable.dart';

/// The lifecycle status of a story node instance.
enum StoryNodeStatus {
  preparation,
  active,
  completed;

  /// Human-readable display name for this status.
  String get displayName => switch (this) {
        StoryNodeStatus.preparation => 'Vorbereitung',
        StoryNodeStatus.active => 'Aktiv',
        StoryNodeStatus.completed => 'Abgeschlossen',
      };

  /// Parses a status from its string representation.
  static StoryNodeStatus fromString(String value) {
    return StoryNodeStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => StoryNodeStatus.preparation,
    );
  }
}

/// A concrete play-through of a [StoryNode] template.
///
/// Created when a game master opens a story node during a session.
/// Holds the group-specific state of that node: notes, status, and
/// any events that occurred during play.
///
/// Multiple sessions can reference the same instance — for example
/// when a chapter spans several real-world sessions.
///
/// [templateId] references the [StoryNode] this instance is based on.
class StoryNodeInstance extends Equatable {
  final String id;
  final String templateId;
  final StoryNodeStatus status;
  final String createdBy;
  final DateTime createdAt;

  const StoryNodeInstance({
    required this.id,
    required this.templateId,
    this.status = StoryNodeStatus.preparation,
    required this.createdBy,
    required this.createdAt,
  });

  factory StoryNodeInstance.fromJson(Map<String, dynamic> json) {
    return StoryNodeInstance(
      id: json['id'] as String,
      templateId: json['template_id'] as String,
      status: StoryNodeStatus.fromString(
        json['status'] as String? ?? 'preparation',
      ),
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'template_id': templateId,
        'status': status.name,
        'created_by': createdBy,
      };

  StoryNodeInstance copyWith({StoryNodeStatus? status}) {
    return StoryNodeInstance(
      id: id,
      templateId: templateId,
      status: status ?? this.status,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, templateId, status, createdBy, createdAt];
}
