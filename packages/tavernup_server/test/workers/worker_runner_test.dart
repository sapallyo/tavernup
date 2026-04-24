import 'package:tavernup_domain/tavernup_domain.dart';
import 'package:tavernup_server/src/workers/worker_runner.dart';
import 'package:test/test.dart';

class _SpyWorker implements IWorker {
  final bool Function(IProcessTask) _canHandle;
  final Future<Map<String, Variable>> Function(IProcessTask) _execute;
  int invocations = 0;

  _SpyWorker({
    required bool Function(IProcessTask) canHandle,
    required Future<Map<String, Variable>> Function(IProcessTask) execute,
  })  : _canHandle = canHandle,
        _execute = execute;

  @override
  bool canHandle(IProcessTask task) => _canHandle(task);

  @override
  Future<Map<String, Variable>> execute(IProcessTask task) {
    invocations++;
    return _execute(task);
  }
}

WorkerTask _externalTask(String id, {String topic = 'entity-operation'}) =>
    WorkerTask(
      id: id,
      name: 'ServiceTask_1',
      processInstanceId: 'pi-1',
      variables: const {},
      topicName: topic,
    );

void main() {
  late MockProcessEngine engine;

  setUp(() => engine = MockProcessEngine());

  test('runOnce fetches, executes matching worker, and completes', () async {
    engine.enqueueWorkerTask(_externalTask('t-1'));
    final worker = _SpyWorker(
      canHandle: (t) => t.name == 'ServiceTask_1',
      execute: (_) async => {'entityId': Variable.string('e-42')},
    );
    final runner = WorkerRunner(
      engine: engine,
      workers: [worker],
      topicName: 'entity-operation',
      workerId: 'w-1',
    );

    await runner.runOnce();

    expect(worker.invocations, 1);
    expect(engine.lockedWorkerTasks, isEmpty,
        reason: 'completed task should release its lock');
  });

  test('runOnce fails task when no worker canHandle', () async {
    engine.enqueueWorkerTask(_externalTask('t-1'));
    final runner = WorkerRunner(
      engine: engine,
      workers: [_SpyWorker(canHandle: (_) => false, execute: (_) async => {})],
      topicName: 'entity-operation',
      workerId: 'w-1',
    );

    await runner.runOnce();

    // MockProcessEngine keeps failed tasks retryable; lock should be released
    expect(engine.lockedWorkerTasks, isEmpty);
  });

  test('runOnce reports worker exceptions as failures', () async {
    engine.enqueueWorkerTask(_externalTask('t-1'));
    final runner = WorkerRunner(
      engine: engine,
      workers: [
        _SpyWorker(
          canHandle: (_) => true,
          execute: (_) async => throw StateError('boom'),
        ),
      ],
      topicName: 'entity-operation',
      workerId: 'w-1',
    );

    await runner.runOnce();

    expect(engine.lockedWorkerTasks, isEmpty);
  });

  test('runOnce filters by topicName', () async {
    engine.enqueueWorkerTask(_externalTask('t-1', topic: 'other-topic'));
    final worker = _SpyWorker(canHandle: (_) => true, execute: (_) async => {});
    final runner = WorkerRunner(
      engine: engine,
      workers: [worker],
      topicName: 'entity-operation',
      workerId: 'w-1',
    );

    await runner.runOnce();

    expect(worker.invocations, 0);
  });

  test('overlapping runOnce calls are serialized', () async {
    engine.enqueueWorkerTask(_externalTask('t-1'));
    var executeCount = 0;
    final worker = _SpyWorker(
      canHandle: (_) => true,
      execute: (_) async {
        executeCount++;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return {};
      },
    );
    final runner = WorkerRunner(
      engine: engine,
      workers: [worker],
      topicName: 'entity-operation',
      workerId: 'w-1',
    );

    // Kick off two concurrent runs. The second should short-circuit.
    final f1 = runner.runOnce();
    final f2 = runner.runOnce();
    await Future.wait([f1, f2]);

    expect(executeCount, 1,
        reason: 'second runOnce must not re-fetch while the first is live');
  });
}
