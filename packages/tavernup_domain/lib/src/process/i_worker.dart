import 'i_process_task.dart';
import 'variable.dart';

/// Interface for a worker that handles a specific type of process task.
///
/// Workers are the bridge between the process engine and the application's
/// domain logic. Each worker is responsible for exactly one task type,
/// identified by its topic name or task definition key.
///
/// The typical usage pattern is:
/// ```dart
/// final worker = registry.find(task);
/// if (worker != null) {
///   final result = await worker.execute(task);
/// }
/// ```
///
/// Implementations should be stateless — all context required for
/// processing must come from the task's variables.
///
/// See also:
/// - [IProcessTask] — the base type for all tasks passed to workers
/// - [IProcessEngine] — the engine that supplies tasks to workers
abstract interface class IWorker {
  /// Returns true if this worker can handle the given task.
  ///
  /// Typically checks the task's name or topic against a known constant:
  /// ```dart
  /// bool canHandle(IProcessTask task) => task.name == 'create-invitation';
  /// ```
  ///
  /// Always call [canHandle] before [execute] to avoid [ArgumentError].
  bool canHandle(IProcessTask task);

  /// Processes the task and returns result variables.
  ///
  /// The returned variables are passed back to the process engine
  /// as the task's output and become available to subsequent steps
  /// in the process.
  ///
  /// Throws [ArgumentError] if the task type is not supported by
  /// this worker. Always call [canHandle] first to verify.
  ///
  /// Throws if any domain operation within the task fails. The caller
  /// is responsible for reporting the failure back to the process engine
  /// via [IProcessEngine.failWorkerTask].
  Future<Map<String, Variable>> execute(IProcessTask task);
}
