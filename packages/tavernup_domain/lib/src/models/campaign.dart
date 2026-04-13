import 'package:equatable/equatable.dart';

/// The lifecycle status of a campaign.
enum CampaignStatus {
  active,
  completed,
  archived;

  /// Parses a status from its string representation.
  ///
  /// Returns [CampaignStatus.active] as a safe default if the value
  /// is not recognised.
  static CampaignStatus fromString(String value) {
    return CampaignStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CampaignStatus.active,
    );
  }
}

/// A campaign is a long-running narrative arc within a game group.
///
/// Campaigns group related [Adventure]s into a coherent story.
/// An adventure can exist independently of a campaign, but a campaign
/// always belongs to a specific [GameGroup].
class Campaign extends Equatable {
  final String id;
  final String gameGroupId;
  final String name;
  final String? description;
  final CampaignStatus status;
  final String createdBy;
  final DateTime createdAt;

  const Campaign({
    required this.id,
    required this.gameGroupId,
    required this.name,
    this.description,
    this.status = CampaignStatus.active,
    required this.createdBy,
    required this.createdAt,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'] as String,
      gameGroupId: json['game_group_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      status: CampaignStatus.fromString(
        json['status'] as String? ?? 'active',
      ),
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'game_group_id': gameGroupId,
        'name': name,
        if (description != null) 'description': description,
        'status': status.name,
        'created_by': createdBy,
      };

  @override
  List<Object?> get props =>
      [id, gameGroupId, name, description, status, createdBy, createdAt];
}
