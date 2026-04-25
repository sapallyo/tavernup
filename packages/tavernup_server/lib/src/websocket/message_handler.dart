import 'dart:convert';

import 'package:tavernup_domain/tavernup_domain.dart';

import '../rba/rba_repository_bundle.dart';
import 'repo_dispatcher.dart';

/// Dispatches incoming WebSocket messages from authenticated clients.
///
/// Each message must be a JSON object with the fields:
/// - `type`: String — the message type (e.g. `validate-user`, `complete-task`)
/// - `requestId`: String — echoed back in the response for client-side matching
/// - `payload`: Map — message-specific data
///
/// Responses always have the shape:
/// ```json
/// { "requestId": "...", "success": true, "data": { ... } }
/// { "requestId": "...", "success": false, "error": "..." }
/// ```
///
/// Repository access is provided via the [RbaRepositoryBundle] passed
/// per call — never via construction-time dependencies. This makes the
/// per-connection principal flow naturally into every dispatch: the
/// `AuthenticatedConnection` builds a bundle for its principal and
/// hands it in for each authenticated frame.
class MessageHandler {
  final Future<void> Function(String taskId, Map<String, Variable> variables)
      _completeUserTask;
  final RepoDispatcher _repoDispatcher;

  MessageHandler({
    required Future<void> Function(
            String taskId, Map<String, Variable> variables)
        completeUserTask,
    RepoDispatcher? repoDispatcher,
  })  : _completeUserTask = completeUserTask,
        _repoDispatcher = repoDispatcher ?? RepoDispatcher();

  /// Processes [message] using the repositories scoped to the calling
  /// connection's principal. Returns the response string the caller
  /// should write back on the socket.
  Future<String> handle(String message, RbaRepositoryBundle repos) async {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(message) as Map<String, dynamic>;
    } catch (_) {
      return _error(null, 'Invalid JSON');
    }

    final type = json['type'] as String?;
    final requestId = json['requestId'] as String?;
    final payload = json['payload'] as Map<String, dynamic>? ?? {};

    if (type == null || requestId == null) {
      return _error(requestId, 'Missing type or requestId');
    }

    try {
      if (type.startsWith('repo.')) {
        final data = await _repoDispatcher.dispatch(type, payload, repos);
        return _success(requestId, {'result': data});
      }
      switch (type) {
        case 'validate-user':
          return await _handleValidateUser(repos.user, requestId, payload);
        case 'complete-task':
          return await _handleCompleteTask(repos.userTask, requestId, payload);
        default:
          return _error(requestId, 'Unknown message type: $type');
      }
    } catch (e) {
      return _error(requestId, e.toString());
    }
  }

  Future<String> _handleValidateUser(
    IUserRepository userRepository,
    String requestId,
    Map<String, dynamic> payload,
  ) async {
    final nickname = payload['nickname'] as String?;
    if (nickname == null) return _error(requestId, 'Missing nickname');

    final user = await userRepository.findByNickname(nickname);
    if (user == null) return _error(requestId, 'User not found: $nickname');

    return _success(requestId, {'userId': user.id});
  }

  Future<String> _handleCompleteTask(
    IUserTaskRepository userTaskRepository,
    String requestId,
    Map<String, dynamic> payload,
  ) async {
    final taskId = payload['taskId'] as String?;
    if (taskId == null) return _error(requestId, 'Missing taskId');

    final rawVariables = payload['variables'] as Map<String, dynamic>? ?? {};
    final variables = rawVariables.map(
      (k, v) => MapEntry(k, Variable.string(v.toString())),
    );

    await _completeUserTask(taskId, variables);
    await userTaskRepository.delete(taskId);

    return _success(requestId, {});
  }

  String _success(String requestId, Map<String, dynamic> data) =>
      jsonEncode({'requestId': requestId, 'success': true, 'data': data});

  String _error(String? requestId, String error) =>
      jsonEncode({'requestId': requestId, 'success': false, 'error': error});
}
