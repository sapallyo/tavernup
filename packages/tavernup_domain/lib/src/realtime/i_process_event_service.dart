import '../process/tasks/user_task.dart';
import '../process/variable.dart';

/// Service interface for process-related realtime communication.
///
/// Bridges the gap between the process engine (Camunda) and the Flutter
/// clients. The worker service keeps this data in sync; clients only
/// interact with this interface, never with Camunda directly.
///
/// Implementations:
/// - `SupabaseProcessEventService`: listens to `pending_user_tasks` via
///   Supabase Realtime, sends completions to the worker via HTTP/WebSocket
/// - `MockProcessEventService`: in-memory implementation for testing
abstract interface class IProcessEventService {
  /// Stream of open user tasks assigned to the current user.
  ///
  /// Emits the full current list whenever it changes — a task arrives,
  /// is completed, or is reassigned. Clients should replace their local
  /// list on each emission rather than trying to diff individual tasks.
  ///
  /// The stream stays active for the lifetime of the service.
  /// An empty list means there are currently no pending tasks.
  Stream<List<UserTask>> get pendingUserTasks;

  /// Completes a user task and passes result variables back to the process.
  ///
  /// This triggers the process to continue from the point where it was
  /// waiting for human input.
  ///
  /// [variables] are merged into the process instance variables and
  /// are available to subsequent tasks and gateways.
  ///
  /// Throws if the task does not exist or has already been completed.
  Future<void> completeUserTask({
    required String taskId,
    Map<String, Variable> variables = const {},
  });
}
