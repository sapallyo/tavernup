import 'package:equatable/equatable.dart';

/// Represents a registered user of the platform.
///
/// A user profile is created once during onboarding and is shared
/// across all game groups and campaigns the user participates in.
/// The [nickname] is the user's public display name and is used
/// for invitations and group membership.
class UserProfile extends Equatable {
  final String id;
  final String nickname;
  final String? avatarUrl;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.nickname,
    this.avatarUrl,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nickname': nickname,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };

  UserProfile copyWith({
    String? nickname,
    String? avatarUrl,
    bool clearAvatar = false,
  }) {
    return UserProfile(
      id: id,
      nickname: nickname ?? this.nickname,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, nickname, avatarUrl, createdAt];
}
