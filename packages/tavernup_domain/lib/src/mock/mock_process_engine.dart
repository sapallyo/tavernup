import 'package:tavernup_domain/tavernup_domain.dart';

/// In-memory mock implementation of [IProcessEngine].
///
/// Does not simulate BPMN execution — it is a state bucket that tests can
/// prime with [enqueueWorkerTask] / [enqueueUserTask] and then exercise
/// through the interface. Completing a task removes it from the bucket;
/// fetchAndLock returns tasks matching the topic and marks them "locked"
/// (excluded from future fetches until complete/fail).
class MockProcessEngine implements IProcessEngine {
  final List<WorkerTask> _workerQueue = [];
  final Map<String, String> _workerLocks = {}; // taskId -> workerId
  final List<UserTask> _userTasks = [];
  int _processCounter = 0;

  // ── Test helpers ──────────────────────────────────────────────────────────

  void enqueueWorkerTask(WorkerTask task) => _workerQueue.add(task);

  void enqueueUserTask(UserTask task) => _userTasks.add(task);

  List<WorkerTask> get lockedWorkerTasks =>
      _workerQueue.where((t) => _workerLocks.containsKey(t.id)).toList();

  // ── IProcessEngine ────────────────────────────────────────────────────────

  @override
  Future<void> deploy({
    required String resourceName,
    required dynamic resource,
  }) async {}

  @override
  Future<String> startProcess({
    required String processKey,
    Map<String, Variable> variables = const {},
  }) async {
    _processCounter++;
    return 'mock-process-$_processCounter';
  }

  @override
  Future<void> cancelProcess(String processInstanceId) async {
    _workerQueue
        .removeWhere((t) => t.processInstanceId == processInstanceId);
    _userTasks.removeWhere((t) => t.processInstanceId == processInstanceId);
  }

  @override
  Future<List<UserTask>> getOpenUserTasks({
    required String userId,
    String? processInstanceId,
  }) async {
    return _userTasks.where((t) {
      if (t.assignee != userId) return false;
      if (processInstanceId != null && t.processInstanceId != processInstanceId) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<void> completeUserTask({
    required String taskId,
    Map<String, Variable> variables = const {},
  }) async {
    final index = _userTasks.indexWhere((t) => t.id == taskId);
    if (index == -1) throw ArgumentError('User task not found: $taskId');
    _userTasks.removeAt(index);
  }

  @override
  Future<List<WorkerTask>> fetchAndLockWorkerTasks({
    required String topicName,
    required String workerId,
    int lockDurationMs = 30000,
    List<String> variables = const [],
  }) async {
    final available = _workerQueue
        .where((t) =>
            t.topicName == topicName && !_workerLocks.containsKey(t.id))
        .toList();
    for (final t in available) {
      _workerLocks[t.id] = workerId;
    }
    return available;
  }

  @override
  Future<void> completeWorkerTask({
    required String taskId,
    required String workerId,
    Map<String, Variable> variables = const {},
  }) async {
    _assertLockedBy(taskId, workerId);
    _workerLocks.remove(taskId);
    _workerQueue.removeWhere((t) => t.id == taskId);
  }

  @override
  Future<void> failWorkerTask({
    required String taskId,
    required String workerId,
    required String errorMessage,
    int retries = 3,
  }) async {
    _assertLockedBy(taskId, workerId);
    _workerLocks.remove(taskId);
    // Task stays in queue; a real engine would decrement retries and eventually
    // move to incident state. The mock keeps it retriable indefinitely.
  }

  void _assertLockedBy(String taskId, String workerId) {
    final lockHolder = _workerLocks[taskId];
    if (lockHolder == null) {
      throw ArgumentError('Worker task not locked: $taskId');
    }
    if (lockHolder != workerId) {
      throw StateError(
        'Worker task $taskId is locked by "$lockHolder", not "$workerId"',
      );
    }
  }
}
