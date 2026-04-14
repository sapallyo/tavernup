import '../process/tasks/user_task.dart';

/// Repository for user tasks synced from the process engine.
///
/// User tasks are created by the process engine (Camunda) and mirrored
/// here so that clients can receive them via Realtime without polling
/// Camunda directly.
///
/// The server writes tasks on webhook notification and deletes them
/// after completion. The client reads them via [watchForAssignee].
abstract interface class IUserTaskRepository {
  /// Persists a new user task received from the process engine.
  Future<void> create(UserTask task);

  /// Removes a completed or cancelled user task by its [taskId].
  Future<void> delete(String taskId);

  /// Returns all open tasks for the given [assigneeId].
  Future<List<UserTask>> getForAssignee(String assigneeId);

  /// Stream of open tasks for the given [assigneeId].
  ///
  /// Emits a new list whenever tasks are added or removed.
  Stream<List<UserTask>> watchForAssignee(String assigneeId);
}
