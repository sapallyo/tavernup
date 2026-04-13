import 'variable.dart';

/// Base interface for all process tasks.
///
/// A process task represents a single unit of work within a running
/// process instance. It carries the context needed to perform that work:
/// which process it belongs to, what it is called, and which variables
/// the process has made available to it.
///
/// There are two concrete task types:
/// - [UserTask]: requires human input before the process can continue
/// - [WorkerTask]: processed automatically by a worker service
///
/// This interface is used by [IWorker.canHandle] to allow workers to
/// inspect any task regardless of its concrete type.
abstract interface class IProcessTask {
  /// Unique identifier of this task instance.
  ///
  /// Assigned by the process engine. Used to complete or fail the task
  /// via [IProcessEngine.completeUserTask] or [IProcessEngine.completeWorkerTask].
  String get id;

  /// The name or definition key of this task as defined in the BPMN model.
  ///
  /// Used by workers to determine whether they can handle the task.
  /// For example, a worker responsible for creating invitations would
  /// check: `task.name == 'create-invitation'`.
  String get name;

  /// The ID of the process instance this task belongs to.
  ///
  /// Can be used to retrieve other tasks or variables belonging to
  /// the same process instance.
  String get processInstanceId;

  /// The process variables made available to this task.
  ///
  /// Contains the data the process has collected up to this point,
  /// as defined by the BPMN model's input mappings.
  /// Result variables are returned separately via the complete/fail calls.
  Map<String, Variable> get variables;
}
