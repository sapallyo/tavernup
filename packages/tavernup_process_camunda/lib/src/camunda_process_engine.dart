import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:tavernup_domain/tavernup_domain.dart';

/// Camunda 7 implementation of [IProcessEngine] via the REST API.
///
/// Wraps the Camunda REST endpoints (typically mounted at `/engine-rest`
/// on the Camunda host). All communication is HTTP/JSON; a [Dio] instance
/// is injectable for testing and for shared configuration (interceptors,
/// timeouts, auth).
///
/// Variable format on the wire follows Camunda's convention:
/// ```json
/// { "varName": { "value": <raw>, "type": "String" } }
/// ```
///
/// Errors from Camunda (4xx/5xx) are surfaced as [StateError] with the
/// server-provided message; 404 on a specific resource is mapped to
/// [ArgumentError] to match the interface contract.
class CamundaProcessEngine implements IProcessEngine {
  final Dio _dio;

  /// [baseUrl] must include the `/engine-rest` prefix, e.g.
  /// `http://localhost:8081/engine-rest`.
  CamundaProcessEngine({required String baseUrl, Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl)) {
    if (dio != null) _dio.options.baseUrl = baseUrl;
  }

  // ── Deployment ────────────────────────────────────────────────────────────

  @override
  Future<void> deploy({
    required String resourceName,
    required Uint8List resource,
  }) async {
    final form = FormData.fromMap({
      'deployment-name': resourceName,
      'deploy-changed-only': 'true',
      resourceName: MultipartFile.fromBytes(
        resource,
        filename: resourceName,
      ),
    });
    await _call('POST', '/deployment/create', data: form);
  }

  // ── Process ───────────────────────────────────────────────────────────────

  @override
  Future<String> startProcess({
    required String processKey,
    Map<String, Variable> variables = const {},
  }) async {
    final response = await _call(
      'POST',
      '/process-definition/key/$processKey/start',
      data: {'variables': _encodeVariables(variables)},
    );
    return response.data['id'] as String;
  }

  @override
  Future<void> cancelProcess(String processInstanceId) async {
    await _call('DELETE', '/process-instance/$processInstanceId',
        notFoundMessage: 'Process instance not found: $processInstanceId');
  }

  // ── User Tasks ────────────────────────────────────────────────────────────

  @override
  Future<List<UserTask>> getOpenUserTasks({
    required String userId,
    String? processInstanceId,
  }) async {
    final query = <String, dynamic>{'assignee': userId};
    if (processInstanceId != null) {
      query['processInstanceId'] = processInstanceId;
    }
    final response =
        await _call('GET', '/task', queryParameters: query);
    final tasks = (response.data as List).cast<Map<String, dynamic>>();
    return tasks.map(_parseUserTask).toList();
  }

  @override
  Future<void> completeUserTask({
    required String taskId,
    Map<String, Variable> variables = const {},
  }) async {
    await _call(
      'POST',
      '/task/$taskId/complete',
      data: {'variables': _encodeVariables(variables)},
      notFoundMessage: 'User task not found: $taskId',
    );
  }

  // ── Worker Tasks ──────────────────────────────────────────────────────────

  @override
  Future<List<WorkerTask>> fetchAndLockWorkerTasks({
    required String topicName,
    required String workerId,
    int lockDurationMs = 30000,
    List<String> variables = const [],
  }) async {
    final response = await _call('POST', '/external-task/fetchAndLock', data: {
      'workerId': workerId,
      'maxTasks': 10,
      'usePriority': true,
      'topics': [
        {
          'topicName': topicName,
          'lockDuration': lockDurationMs,
          if (variables.isNotEmpty) 'variables': variables,
        }
      ],
    });
    final tasks = (response.data as List).cast<Map<String, dynamic>>();
    return tasks.map(_parseWorkerTask).toList();
  }

  @override
  Future<void> completeWorkerTask({
    required String taskId,
    required String workerId,
    Map<String, Variable> variables = const {},
  }) async {
    await _call(
      'POST',
      '/external-task/$taskId/complete',
      data: {
        'workerId': workerId,
        'variables': _encodeVariables(variables),
      },
      notFoundMessage: 'Worker task not found: $taskId',
    );
  }

  @override
  Future<void> failWorkerTask({
    required String taskId,
    required String workerId,
    required String errorMessage,
    int retries = 3,
  }) async {
    await _call(
      'POST',
      '/external-task/$taskId/failure',
      data: {
        'workerId': workerId,
        'errorMessage': errorMessage,
        'retries': retries,
        'retryTimeout': 5000,
      },
      notFoundMessage: 'Worker task not found: $taskId',
    );
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  /// Single HTTP-call wrapper that normalizes Camunda error responses into
  /// [StateError] (or [ArgumentError] for 404 when [notFoundMessage] is set).
  Future<Response<dynamic>> _call(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    String? notFoundMessage,
  }) async {
    try {
      return await _dio.request<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404 && notFoundMessage != null) {
        throw ArgumentError(notFoundMessage);
      }
      final body = e.response?.data;
      final serverMessage = body is Map
          ? (body['message'] as String?) ?? body.toString()
          : (body?.toString() ?? e.message ?? 'unknown error');
      throw StateError('Camunda ${method} $path failed: $serverMessage');
    }
  }

  Map<String, dynamic> _encodeVariables(Map<String, Variable> variables) {
    return variables.map((key, v) => MapEntry(key, _encodeVariable(v)));
  }

  Map<String, dynamic> _encodeVariable(Variable v) {
    return switch (v.type) {
      VariableType.string => {'value': v.value, 'type': 'String'},
      VariableType.integer => {'value': v.value, 'type': 'Integer'},
      VariableType.double => {'value': v.value, 'type': 'Double'},
      VariableType.boolean => {'value': v.value, 'type': 'Boolean'},
      VariableType.json => {
          'value': jsonEncode(v.value),
          'type': 'Json',
        },
    };
  }

  Map<String, Variable> _decodeVariables(dynamic raw) {
    if (raw == null) return const {};
    final map = (raw as Map<String, dynamic>);
    return map.map((key, value) {
      final v = value as Map<String, dynamic>;
      return MapEntry(key, _decodeVariable(v));
    });
  }

  Variable _decodeVariable(Map<String, dynamic> v) {
    final type = (v['type'] as String).toLowerCase();
    final raw = v['value'];
    return switch (type) {
      'string' => Variable.string(raw as String),
      'integer' || 'long' || 'short' =>
        Variable.integer((raw as num).toInt()),
      'double' || 'float' => Variable.double((raw as num).toDouble()),
      'boolean' => Variable.boolean(raw as bool),
      'json' => Variable.json(
          raw is String
              ? jsonDecode(raw) as Map<String, dynamic>
              : raw as Map<String, dynamic>,
        ),
      _ => Variable.string(raw?.toString() ?? ''),
    };
  }

  UserTask _parseUserTask(Map<String, dynamic> json) {
    return UserTask(
      id: json['id'] as String,
      name: (json['name'] as String?) ??
          (json['taskDefinitionKey'] as String? ?? ''),
      processInstanceId: json['processInstanceId'] as String,
      assignee: (json['assignee'] as String?) ?? '',
      variables: _decodeVariables(json['variables']),
      created: DateTime.parse(json['created'] as String),
    );
  }

  WorkerTask _parseWorkerTask(Map<String, dynamic> json) {
    final topicName = (json['topicName'] as String?) ?? '';
    return WorkerTask(
      id: json['id'] as String,
      name: (json['activityId'] as String?) ?? topicName,
      processInstanceId: json['processInstanceId'] as String,
      variables: _decodeVariables(json['variables']),
      topicName: topicName,
    );
  }
}
