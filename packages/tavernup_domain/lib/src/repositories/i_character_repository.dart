import '../models/character.dart';

/// Repository interface for managing characters.
///
/// A character is owned by a single user but can be made visible
/// to other users — for example to fellow players in a game group.
///
/// Implementations:
/// - `SupabaseCharacterRepository`: persists to Supabase
/// - `MockCharacterRepository`: in-memory implementation for testing
abstract interface class ICharacterRepository {
  /// Returns all characters owned by [ownerId].
  Future<List<Character>> getOwned(String ownerId);

  /// Returns all characters visible to [userId].
  ///
  /// Includes owned characters and characters where [userId]
  /// has been granted visibility via [grantVisibility].
  Future<List<Character>> getVisible(String userId);

  /// Returns the character with [id], or null if not found.
  Future<Character?> getById(String id);

  /// Saves a character — creates it if new, updates it if existing.
  Future<void> save(Character character);

  /// Permanently deletes the character with [id].
  Future<void> delete(String id);

  /// Grants [userId] read access to [characterId].
  Future<void> grantVisibility(String characterId, String userId);

  /// Revokes read access to [characterId] from [userId].
  Future<void> revokeVisibility(String characterId, String userId);

  /// Returns a stream of all characters owned by [ownerId].
  ///
  /// Emits the current list immediately, then re-emits whenever
  /// the list changes.
  Stream<List<Character>> watchOwned(String ownerId);
}
