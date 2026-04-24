import 'package:tavernup_domain/tavernup_domain.dart';

/// Client-side [IProcessEventService] implementation.
///
/// Composes two interfaces to fulfill the contract:
/// - [IUserTaskRepository.watchForAssignee] for the live inbox of pending
///   tasks (uses Supabase Realtime under the hood — see
///   `SupabaseUserTaskRepository`).
/// - [IRealtimeTransport.request] for task completion, which routes through
///   `tavernup_server` so Camunda is updated and the `user_tasks` row is
///   removed in the same operation.
///
/// [userId] is fixed for the lifetime of the instance. On logout the
/// enclosing Riverpod provider is expected to be disposed and rebuilt
/// for the next user.
class ProcessEventService implements IProcessEventService {
  final IUserTaskRepository _userTaskRepository;
  final IRealtimeTransport _transport;
  final String _userId;

  ProcessEventService({
    required IUserTaskRepository userTaskRepository,
    required IRealtimeTransport transport,
    required String userId,
  })  : _userTaskRepository = userTaskRepository,
        _transport = transport,
        _userId = userId;

  @override
  Stream<List<UserTask>> get pendingUserTasks =>
      _userTaskRepository.watchForAssignee(_userId);

  @override
  Future<void> completeUserTask({
    required String taskId,
    Map<String, Variable> variables = const {},
  }) async {
    final rawVariables = variables.map((k, v) => MapEntry(k, v.value));
    await _transport.request('complete-task', {
      'taskId': taskId,
      'variables': rawVariables,
    });
  }
}
