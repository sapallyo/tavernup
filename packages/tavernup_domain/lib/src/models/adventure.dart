import 'package:equatable/equatable.dart';

/// The lifecycle status of an adventure.
enum AdventureStatus {
  preparation,
  active,
  completed;

  /// Human-readable display name for this status.
  String get displayName => switch (this) {
        AdventureStatus.preparation => 'Vorbereitung',
        AdventureStatus.active => 'Aktiv',
        AdventureStatus.completed => 'Abgeschlossen',
      };

  /// Parses a status from its string representation.
  ///
  /// Returns [AdventureStatus.preparation] as a safe default if the
  /// value is not recognised.
  static AdventureStatus fromString(String value) {
    return AdventureStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AdventureStatus.preparation,
    );
  }
}

/// A single adventure (session or short arc) within a game group.
///
/// Adventures are the primary unit of play. They can exist standalone
/// or as part of a [Campaign]. Each adventure tracks which characters
/// participated via [AdventureCharacter] entries.
///
/// The [campaignId] is optional — an adventure without a campaign is
/// a one-shot or standalone session.
class Adventure extends Equatable {
  final String id;
  final String gameGroupId;
  final String? campaignId;
  final String name;
  final String? description;
  final AdventureStatus status;
  final String createdBy;
  final DateTime createdAt;

  const Adventure({
    required this.id,
    required this.gameGroupId,
    this.campaignId,
    required this.name,
    this.description,
    this.status = AdventureStatus.preparation,
    required this.createdBy,
    required this.createdAt,
  });

  factory Adventure.fromJson(Map<String, dynamic> json) {
    return Adventure(
      id: json['id'] as String,
      gameGroupId: json['game_group_id'] as String,
      campaignId: json['campaign_id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      status: AdventureStatus.fromString(
        json['status'] as String? ?? 'preparation',
      ),
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'game_group_id': gameGroupId,
        if (campaignId != null) 'campaign_id': campaignId,
        'name': name,
        if (description != null) 'description': description,
        'status': status.name,
        'created_by': createdBy,
      };

  @override
  List<Object?> get props => [
        id,
        gameGroupId,
        campaignId,
        name,
        description,
        status,
        createdBy,
        createdAt
      ];
}
