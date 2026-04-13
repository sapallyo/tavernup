import 'package:equatable/equatable.dart';

/// The role a user can hold within a game group.
///
/// Roles determine which actions a user may perform within the group,
/// such as managing members (admin), running sessions (gm),
/// or participating as a player.
enum GameGroupRole {
  admin,
  gm,
  player;

  /// Human-readable display name for this role.
  String get displayName => switch (this) {
        GameGroupRole.admin => 'Admin',
        GameGroupRole.gm => 'Spielleiter',
        GameGroupRole.player => 'Spieler',
      };

  /// Parses a role from its string representation.
  ///
  /// Returns [GameGroupRole.player] as a safe default if the value
  /// is not recognised — for example when reading legacy data.
  static GameGroupRole fromString(String value) {
    return GameGroupRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GameGroupRole.player,
    );
  }
}

/// Represents a user's membership in a specific game group.
///
/// Membership is created when a user accepts an invitation to a group.
/// The [role] determines what the user can do within the group.
/// The [invitedBy] field records who sent the invitation, if applicable.
class GameGroupMembership extends Equatable {
  final String id;
  final String gameGroupId;
  final String userId;
  final GameGroupRole role;
  final String? invitedBy;
  final DateTime joinedAt;

  const GameGroupMembership({
    required this.id,
    required this.gameGroupId,
    required this.userId,
    required this.role,
    this.invitedBy,
    required this.joinedAt,
  });

  factory GameGroupMembership.fromJson(Map<String, dynamic> json) {
    return GameGroupMembership(
      id: json['id'] as String,
      gameGroupId: json['game_group_id'] as String,
      userId: json['user_id'] as String,
      role: GameGroupRole.fromString(json['role'] as String),
      invitedBy: json['invited_by'] as String?,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'game_group_id': gameGroupId,
        'user_id': userId,
        'role': role.name,
        if (invitedBy != null) 'invited_by': invitedBy,
      };

  @override
  List<Object?> get props =>
      [id, gameGroupId, userId, role, invitedBy, joinedAt];
}
