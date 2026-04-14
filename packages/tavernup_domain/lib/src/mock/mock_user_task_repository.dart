import 'package:tavernup_domain/tavernup_domain.dart';
import 'dart:async';

/// In-memory mock implementation of [IUserTaskRepository].
///
/// Intended for use in tests and local development.
/// [watchForAssignee] emits a new list on every mutation.
class MockUserTaskRepository implements IUserTaskRepository {
  final List<UserTask> _tasks = [];
  final _controller = StreamController<void>.broadcast();

  @override
  Future<void> create(UserTask task) async {
    if (_tasks.any((t) => t.id == task.id)) {
      throw ArgumentError('UserTask already exists: ${task.id}');
    }
    _tasks.add(task);
    _controller.add(null);
  }

  @override
  Future<void> delete(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) throw ArgumentError('UserTask not found: $taskId');
    _tasks.removeAt(index);
    _controller.add(null);
  }

  @override
  Future<List<UserTask>> getForAssignee(String assigneeId) async {
    return _tasks.where((t) => t.assignee == assigneeId).toList();
  }

  @override
  Stream<List<UserTask>> watchForAssignee(String assigneeId) {
    return _controller.stream.map(
      (_) => _tasks.where((t) => t.assignee == assigneeId).toList(),
    );
  }

  /// Releases resources. Call in [tearDown] after tests.
  Future<void> dispose() => _controller.close();
}
