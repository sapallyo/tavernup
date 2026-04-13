import 'package:equatable/equatable.dart';
import 'process_task.dart';

class UserTask extends ProcessTask with EquatableMixin {
  final String assignee;
  final DateTime created;

  const UserTask({
    required super.id,
    required super.name,
    required super.processInstanceId,
    required super.variables,
    required this.assignee,
    required this.created,
  });

  @override
  List<Object?> get props => [id, name, processInstanceId, assignee, created];

  @override
  String toString() => 'UserTask(id: $id, name: $name, assignee: $assignee)';
}
