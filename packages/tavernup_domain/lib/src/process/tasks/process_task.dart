import '../variable.dart';
import '../i_process_task.dart';

abstract class ProcessTask implements IProcessTask {
  @override
  final String id;
  @override
  final String name;
  @override
  final String processInstanceId;
  @override
  final Map<String, Variable> variables;

  const ProcessTask({
    required this.id,
    required this.name,
    required this.processInstanceId,
    required this.variables,
  });
}
