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

  /// Uploads an avatar image for [userId].
  ///
  /// Returns the public URL of the uploaded image,
  /// or null if the upload failed.
  Future<String?> uploadAvatar(String userId);
}
