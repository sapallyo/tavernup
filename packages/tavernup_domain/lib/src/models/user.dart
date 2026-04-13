import 'package:equatable/equatable.dart';

/// Represents a registered user of the platform.
///
/// [id] is the Supabase Auth UUID — the same ID used across all
/// auth and database operations. The platform never manages
/// authentication itself; it only stores domain-relevant user data.
///
/// A user can be a member of multiple game groups, own characters,
/// and participate in adventures across different RPG systems.
class User extends Equatable {
  final String id;
  final String nickname;
  final String? avatarUrl;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.nickname,
    this.avatarUrl,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
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

  User copyWith({
    String? nickname,
    String? avatarUrl,
    bool clearAvatar = false,
  }) {
    return User(
      id: id,
      nickname: nickname ?? this.nickname,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, nickname, avatarUrl, createdAt];
}
