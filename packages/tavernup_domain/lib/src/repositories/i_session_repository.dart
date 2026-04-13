import '../models/session.dart';
import '../models/adventure_character.dart';
import '../models/story_node_instance.dart';

/// Repository interface for managing sessions.
///
/// A session is the central binding element connecting a game group,
/// its players, and the story content being played.
///
/// Sessions are owned by a [GameGroup] via the group's session ID list.
///
/// Implementations:
/// - `SupabaseSessionRepository`: persists to Supabase
/// - `MockSessionRepository`: in-memory implementation for testing
abstract interface class ISessionRepository {
  /// Returns the session with [id], or null if not found.
  Future<Session?> getById(String id);

  /// Returns all sessions for the given list of [sessionIds].
  ///
  /// Used by [GameGroup] to load its sessions.
  Future<List<Session>> getByIds(List<String> sessionIds);

  /// Creates a new session.
  Future<Session> create();

  /// Adds a [StoryNodeInstance] to the session's instance list.
  Future<void> addInstance(String sessionId, String instanceId);

  /// Removes a [StoryNodeInstance] from the session's instance list.
  Future<void> removeInstance(String sessionId, String instanceId);

  /// Adds a participant to the session.
  Future<void> addParticipant(
    String sessionId,
    AdventureCharacter participant,
  );

  /// Removes a participant from the session.
  Future<void> removeParticipant(String sessionId, String participantId);

  /// Permanently deletes the session with [id].
  Future<void> delete(String id);

  /// Returns a stream of sessions for the given [sessionIds].
  ///
  /// Emits the current list immediately, then re-emits on changes.
  Stream<List<Session>> watchByIds(List<String> sessionIds);
}
