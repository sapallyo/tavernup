import 'dart:convert';

import 'package:supabase/supabase.dart' hide User, Session;
import 'package:tavernup_domain/tavernup_domain.dart';

/// Supabase implementation of [IUserTaskRepository].
///
/// Reads and writes to the `user_tasks` table in Supabase.
/// Write operations are performed by the server via service_role.
/// The client only reads and watches via RLS-filtered queries.
class SupabaseUserTaskRepository implements IUserTaskRepository {
  final SupabaseClient _client;

  SupabaseUserTaskRepository(this._client);

  @override
  Future<void> create(UserTask task) async {
    await _client.from('user_tasks').insert({
      'id': task.id,
      'name': task.name,
      'process_instance_id': task.processInstanceId,
      'assignee': task.assignee,
      'variables': _encodeVariables(task.variables),
      'created_at': task.created.toIso8601String(),
    });
  }

  @override
  Future<void> delete(String taskId) async {
    await _client.from('user_tasks').delete().eq('id', taskId);
  }

  @override
  Future<List<UserTask>> getForAssignee(String assigneeId) async {
    final data =
        await _client.from('user_tasks').select().eq('assignee', assigneeId);
    return (data as List).map((e) => _fromJson(e)).toList();
  }

  @override
  Stream<List<UserTask>> watchForAssignee(String assigneeId) {
    return _client
        .from('user_tasks')
        .stream(primaryKey: ['id'])
        .eq('assignee', assigneeId)
        .map((data) => data.map((e) => _fromJson(e)).toList());
  }

  UserTask _fromJson(Map<String, dynamic> json) {
    return UserTask(
      id: json['id'] as String,
      name: json['name'] as String,
      processInstanceId: json['process_instance_id'] as String,
      assignee: json['assignee'] as String,
      variables: _decodeVariables(json['variables']),
      created: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> _encodeVariables(Map<String, Variable> variables) {
    return variables.map((key, variable) => MapEntry(key, {
          'type': variable.type.name,
          'value': variable.value,
        }));
  }

  Map<String, Variable> _decodeVariables(dynamic raw) {
    if (raw == null) return {};
    final map = raw is String
        ? jsonDecode(raw) as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return map.map((key, value) {
      final type = VariableType.values.firstWhere(
        (t) => t.name == value['type'],
        orElse: () => VariableType.string,
      );
      return MapEntry(key, Variable.fromTypeAndValue(type, value['value']));
    });
  }
}
