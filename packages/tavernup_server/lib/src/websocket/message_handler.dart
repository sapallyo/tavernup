import 'dart:convert';

import 'package:tavernup_domain/tavernup_domain.dart';

/// Handles incoming WebSocket messages from the Flutter client.
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
class MessageHandler {
  final IUserRepository _userRepository;
  final IUserTaskRepository _userTaskRepository;
  final Future<void> Function(String taskId, Map<String, Variable> variables)
      _completeUserTask;

  MessageHandler({
    required IUserRepository userRepository,
    required IUserTaskRepository userTaskRepository,
    required Future<void> Function(
            String taskId, Map<String, Variable> variables)
        completeUserTask,
  })  : _userRepository = userRepository,
        _userTaskRepository = userTaskRepository,
        _completeUserTask = completeUserTask;

  /// Processes a raw WebSocket message and returns the response string.
  Future<String> handle(String message) async {
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
      switch (type) {
        case 'validate-user':
          return await _handleValidateUser(requestId, payload);
        case 'complete-task':
          return await _handleCompleteTask(requestId, payload);
        default:
          return _error(requestId, 'Unknown message type: $type');
      }
    } catch (e) {
      return _error(requestId, e.toString());
    }
  }

  Future<String> _handleValidateUser(
      String requestId, Map<String, dynamic> payload) async {
    final nickname = payload['nickname'] as String?;
    if (nickname == null) return _error(requestId, 'Missing nickname');

    final user = await _userRepository.findByNickname(nickname);
    if (user == null) return _error(requestId, 'User not found: $nickname');

    return _success(requestId, {'userId': user.id});
  }

  Future<String> _handleCompleteTask(
      String requestId, Map<String, dynamic> payload) async {
    final taskId = payload['taskId'] as String?;
    if (taskId == null) return _error(requestId, 'Missing taskId');

    final rawVariables = payload['variables'] as Map<String, dynamic>? ?? {};
    final variables = rawVariables.map(
      (k, v) => MapEntry(k, Variable.string(v.toString())),
    );

    await _completeUserTask(taskId, variables);
    await _userTaskRepository.delete(taskId);

    return _success(requestId, {});
  }

  String _success(String requestId, Map<String, dynamic> data) =>
      jsonEncode({'requestId': requestId, 'success': true, 'data': data});

  String _error(String? requestId, String error) =>
      jsonEncode({'requestId': requestId, 'success': false, 'error': error});
}
