import 'package:equatable/equatable.dart';
import 'process_task.dart';

class WorkerTask extends ProcessTask with EquatableMixin {
  final String topicName;

  const WorkerTask({
    required super.id,
    required super.name,
    required super.processInstanceId,
    required super.variables,
    required this.topicName,
  });

  @override
  List<Object?> get props => [id, name, processInstanceId, topicName];

  @override
  String toString() =>
      'WorkerTask(id: $id, name: $name, topicName: $topicName)';
}
