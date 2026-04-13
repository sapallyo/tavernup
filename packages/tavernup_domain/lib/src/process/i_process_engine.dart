import 'dart:typed_data';
import 'variable.dart';
import 'tasks/user_task.dart';
import 'tasks/worker_task.dart';

/// Central interface for interacting with a BPMN process engine.
///
/// Abstracts the underlying process automation technology (e.g. Camunda 7)
/// so that the rest of the application has no direct dependency on it.
///
/// There are three categories of operations:
/// - **Deployment**: uploading process definitions to the engine
/// - **User Tasks**: tasks that require human input to proceed
/// - **Worker Tasks**: tasks that are processed automatically by a worker service
///
/// Implementations:
/// - `CamundaProcessEngine`: delegates to the Camunda 7 REST API
/// - `MockProcessEngine`: in-memory implementation for testing
abstract interface class IProcessEngine {
  // ── Deployment ──────────────────────────────────────────────────────────────

  /// Deploys a BPMN resource to the process engine.
  ///
  /// If a process with the same key already exists, it is deployed
  /// as a new version. Existing process instances continue on their
  /// current version; new instances use the latest version.
  ///
  /// [resourceName] is used as the deployment name and should match
  /// the filename (e.g. `invitation-process.bpmn`).
  Future<void> deploy({
    required String resourceName,
    required Uint8List resource,
  });

  // ── Process ─────────────────────────────────────────────────────────────────

  /// Starts a new process instance for the given process definition key.
  ///
  /// [processKey] must match the `id` attribute of the BPMN process element.
  /// [variables] are passed as initial process variables and are available
  /// to all tasks and gateways within the process.
  ///
  /// Returns the process instance ID which can be used to track or
  /// cancel the instance later.
  Future<String> startProcess({
    required String processKey,
    Map<String, Variable> variables = const {},
  });

  /// Cancels a running process instance and all its active tasks.
  ///
  /// Has no effect if the instance has already completed or was
  /// previously cancelled.
  Future<void> cancelProcess(String processInstanceId);

  // ── User Tasks ───────────────────────────────────────────────────────────────

  /// Returns all open user tasks assigned to the given user.
  ///
  /// User tasks represent points in the process where a human decision
  /// or input is required before the process can continue.
  ///
  /// Optionally filtered by [processInstanceId] to retrieve tasks
  /// belonging to a specific process instance only.
  Future<List<UserTask>> getOpenUserTasks({
    required String userId,
    String? processInstanceId,
  });

  /// Completes a user task and allows the process to continue.
  ///
  /// [variables] are merged into the process instance variables and
  /// are available to subsequent tasks and gateways.
  ///
  /// Throws if the task does not exist or is already completed.
  Future<void> completeUserTask({
    required String taskId,
    Map<String, Variable> variables = const {},
  });

  // ── Worker Tasks ─────────────────────────────────────────────────────────────

  /// Fetches available worker tasks for the given topic and locks them.
  ///
  /// Worker tasks are service tasks in the BPMN process that are handled
  /// automatically by a worker service rather than a human.
  ///
  /// The lock prevents other workers from picking up the same task.
  /// It must be released within [lockDurationMs] milliseconds by calling
  /// either [completeWorkerTask] or [failWorkerTask].
  ///
  /// [variables] specifies which process variables to include in the
  /// response. Pass an empty list to include all variables.
  ///
  /// [workerId] identifies this worker instance and must be passed to
  /// [completeWorkerTask] and [failWorkerTask].
  Future<List<WorkerTask>> fetchAndLockWorkerTasks({
    required String topicName,
    required String workerId,
    int lockDurationMs = 30000,
    List<String> variables = const [],
  });

  /// Completes a worker task successfully and passes result variables.
  ///
  /// [variables] are merged into the process instance variables and
  /// are available to subsequent tasks and gateways.
  ///
  /// [workerId] must match the ID used when the task was locked via
  /// [fetchAndLockWorkerTasks].
  Future<void> completeWorkerTask({
    required String taskId,
    required String workerId,
    Map<String, Variable> variables = const {},
  });

  /// Reports a worker task as failed.
  ///
  /// The process engine will retry the task automatically after a delay
  /// until [retries] is exhausted. When retries reach zero, the task
  /// moves to the incident state and requires manual intervention.
  ///
  /// [workerId] must match the ID used when the task was locked via
  /// [fetchAndLockWorkerTasks].
  Future<void> failWorkerTask({
    required String taskId,
    required String workerId,
    required String errorMessage,
    int retries = 3,
  });
}
