import 'package:tavernup_domain/tavernup_domain.dart';

/// Bridges the process engine with domain workers.
///
/// One cycle of [runOnce]:
/// 1. `fetchAndLock` external tasks for [topicName]
/// 2. For each locked task, find a matching [IWorker] from [workers]
///    (via `canHandle`) and call `execute`
/// 3. Report the result: `completeWorkerTask` on success,
///    `failWorkerTask` on exception
///
/// Runs are serialized — overlapping [runOnce] calls short-circuit so we
/// never hold two open fetchAndLock requests for the same worker. That
/// keeps webhook-triggered runs and the safety-net timer from stepping
/// on each other.
class WorkerRunner {
  final IProcessEngine _engine;
  final List<IWorker> _workers;
  final String _topicName;
  final String _workerId;
  final int _lockDurationMs;

  var _running = false;

  WorkerRunner({
    required IProcessEngine engine,
    required List<IWorker> workers,
    required String topicName,
    required String workerId,
    int lockDurationMs = 30000,
  })  : _engine = engine,
        _workers = workers,
        _topicName = topicName,
        _workerId = workerId,
        _lockDurationMs = lockDurationMs;

  /// Executes a single fetch/dispatch/complete cycle.
  ///
  /// Returns silently when another run is already in progress.
  Future<void> runOnce() async {
    if (_running) return;
    _running = true;
    try {
      final tasks = await _engine.fetchAndLockWorkerTasks(
        topicName: _topicName,
        workerId: _workerId,
        lockDurationMs: _lockDurationMs,
      );
      for (final task in tasks) {
        await _dispatch(task);
      }
    } finally {
      _running = false;
    }
  }

  Future<void> _dispatch(WorkerTask task) async {
    final worker = _workers.where((w) => w.canHandle(task)).firstOrNull;
    if (worker == null) {
      await _engine.failWorkerTask(
        taskId: task.id,
        workerId: _workerId,
        errorMessage: 'No worker registered for task "${task.name}"',
        retries: 0,
      );
      return;
    }
    try {
      final result = await worker.execute(task);
      await _engine.completeWorkerTask(
        taskId: task.id,
        workerId: _workerId,
        variables: result,
      );
    } catch (e) {
      await _engine.failWorkerTask(
        taskId: task.id,
        workerId: _workerId,
        errorMessage: e.toString(),
      );
    }
  }
}
