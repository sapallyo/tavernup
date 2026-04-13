import 'package:equatable/equatable.dart';
import 'game_group_membership.dart';

/// The lifecycle status of an invitation.
///
/// An invitation starts as [pending] and transitions to either
/// [accepted] or [rejected] when the invited user responds.
enum InvitationStatus {
  pending,
  accepted,
  rejected;

  /// Parses a status from its string representation.
  ///
  /// Returns [InvitationStatus.pending] as a safe default if the value
  /// is not recognised — for example when reading legacy data.
  static InvitationStatus fromString(String value) {
    return InvitationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => InvitationStatus.pending,
    );
  }
}

/// Represents an invitation for a user to join a game group.
///
/// Invitations are created by group admins or game masters and sent
/// to a specific user identified by [invitedUserId]. They expire after
/// a set duration and can only be accepted or rejected while [isValid].
///
/// Once accepted, a [GameGroupMembership] is created for the invited user
/// with the specified [role].
class Invitation extends Equatable {
  final String id;
  final String gameGroupId;
  final GameGroupRole role;
  final String createdBy;
  final String invitedUserId;
  final DateTime expiresAt;
  final DateTime createdAt;
  final InvitationStatus status;

  const Invitation({
    required this.id,
    required this.gameGroupId,
    required this.role,
    required this.createdBy,
    required this.invitedUserId,
    required this.expiresAt,
    required this.createdAt,
    this.status = InvitationStatus.pending,
  });

  /// Returns true if the invitation has passed its expiry date.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Returns true if the invitation was accepted by the invited user.
  bool get isAccepted => status == InvitationStatus.accepted;

  /// Returns true if the invitation can still be acted upon.
  ///
  /// An invitation is valid if it has not expired and is still pending.
  bool get isValid => !isExpired && status == InvitationStatus.pending;

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['id'] as String,
      gameGroupId: json['game_group_id'] as String,
      role: GameGroupRole.fromString(json['role'] as String),
      createdBy: json['created_by'] as String,
      invitedUserId: json['invited_user_id'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      status:
          InvitationStatus.fromString(json['status'] as String? ?? 'pending'),
    );
  }

  Map<String, dynamic> toJson() => {
        'game_group_id': gameGroupId,
        'role': role.name,
        'created_by': createdBy,
        'invited_user_id': invitedUserId,
        'status': status.name,
      };

  Invitation copyWith({
    String? id,
    String? gameGroupId,
    GameGroupRole? role,
    String? createdBy,
    String? invitedUserId,
    DateTime? expiresAt,
    DateTime? createdAt,
    InvitationStatus? status,
  }) {
    return Invitation(
      id: id ?? this.id,
      gameGroupId: gameGroupId ?? this.gameGroupId,
      role: role ?? this.role,
      createdBy: createdBy ?? this.createdBy,
      invitedUserId: invitedUserId ?? this.invitedUserId,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        id,
        gameGroupId,
        role,
        createdBy,
        invitedUserId,
        expiresAt,
        createdAt,
        status,
      ];
}
