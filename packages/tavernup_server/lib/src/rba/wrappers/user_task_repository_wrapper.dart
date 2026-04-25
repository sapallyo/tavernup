import 'package:tavernup_domain/tavernup_domain.dart';

import '../principal.dart';

/// Authorizing wrapper around a raw [IUserTaskRepository].
///
/// Currently pass-through: every call delegates to the raw repository
/// regardless of the principal. Filter and projection logic per
/// principal will be added when the role catalog is filled in.
class UserTaskRepositoryWrapper implements IUserTaskRepository {
  final IUserTaskRepository _raw;
  // ignore: unused_field
  final Principal _principal;

  UserTaskRepositoryWrapper(this._raw, this._principal);

  @override
  Future<void> create(UserTask task) => _raw.create(task);

  @override
  Future<void> delete(String taskId) => _raw.delete(taskId);

  @override
  Future<List<UserTask>> getForAssignee(String assigneeId) =>
      _raw.getForAssignee(assigneeId);

  @override
  Stream<List<UserTask>> watchForAssignee(String assigneeId) =>
      _raw.watchForAssignee(assigneeId);
}
