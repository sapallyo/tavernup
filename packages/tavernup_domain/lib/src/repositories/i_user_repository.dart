import 'dart:typed_data';

import '../models/user.dart';

/// Repository interface for managing users.
///
/// Each authenticated user has exactly one [User] record.
/// It is created on first login and updated by the user over time.
///
/// [User.id] corresponds to the Supabase Auth UUID — no separate
/// mapping between auth identity and domain user is needed.
///
/// Implementations:
/// - `SupabaseUserRepository`: persists to Supabase
/// - `MockUserRepository`: in-memory implementation for testing
abstract interface class IUserRepository {
  /// Returns the [User] of the currently authenticated session,
  /// or null if no profile exists yet.
  Future<User?> getOwn();

  /// Returns the [User] for [userId], or null if not found.
  Future<User?> getById(String userId);

  /// Searches for a user by their nickname.
  ///
  /// Returns null if no user with that nickname exists.
  /// Used during the invitation flow to resolve a nickname
  /// to a concrete user ID.
  Future<User?> findByNickname(String nickname);

  /// Saves a user record — creates it if new, updates it if existing.
  Future<User> save(User user);

  /// Uploads an avatar image for [userId] and returns its **storage path**.
  ///
  /// [bytes] is the raw image data; [contentType] (e.g. `image/png`,
  /// `image/jpeg`) is used for Storage metadata and content serving.
  /// Subsequent uploads for the same user overwrite the previous avatar.
  ///
  /// The returned path (e.g. `{userId}/avatar`) should be persisted on the
  /// [User] record via [save]. To obtain a viewable URL, call
  /// [getAvatarSignedUrl] with that path. The bucket is private, so
  /// permanent URLs do not exist.
  ///
  /// Returns null if the upload fails.
  Future<String?> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String contentType,
  });

  /// Returns a short-lived signed URL for [path] (typically the path
  /// previously returned by [uploadAvatar] and stored on [User.avatarUrl]).
  ///
  /// [expiresIn] controls how long the URL stays valid. Callers
  /// (typically image widgets) should refresh by calling this method
  /// again before the URL expires.
  ///
  /// Returns null if the file does not exist or the URL cannot be
  /// generated (e.g. caller lacks permission).
  Future<String?> getAvatarSignedUrl({
    required String path,
    Duration expiresIn = const Duration(hours: 1),
  });
}
