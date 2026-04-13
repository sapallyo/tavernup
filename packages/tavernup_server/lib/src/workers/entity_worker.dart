import 'package:tavernup_domain/tavernup_domain.dart';

/// Generic worker for CRUD operations on domain entities.
///
/// Reads the following variables from the task:
/// - `entityType`: String — e.g. `invitation`, `membership`
/// - `operation`: String — `create`, `update`, or `delete`
/// - `field:<name>`: String — field mapping, either:
///     - `$variableName` — resolves to the value of a process variable
///     - `staticValue`   — used as-is
///
/// Returns:
/// - `entityId`: String — ID of the created entity (only for `create`)
///
/// Example BPMN extension properties for creating an invitation:
/// ```
/// entityType         = invitation
/// operation          = create
/// field:gameGroupId  = $groupId
/// field:invitedUserId = $invitedUserId
/// field:role         = player
/// ```
class EntityWorker implements IWorker {
  final EntityRepositoryRegistry _registry;

  EntityWorker(this._registry);

  @override
  bool canHandle(IProcessTask task) =>
      task is WorkerTask &&
      task.variables.containsKey('entityType') &&
      task.variables.containsKey('operation');

  @override
  Future<Map<String, Variable>> execute(IProcessTask task) async {
    if (task is! WorkerTask) {
      throw ArgumentError(
        'EntityWorker requires a WorkerTask, got ${task.runtimeType}',
      );
    }

    final entityType = task.variables['entityType']!.value as String;
    final operation = task.variables['operation']!.value as String;
    final data = _resolveFields(task);
    final repository = _registry.findByType(entityType);

    switch (operation) {
      case 'create':
        final id = await repository.create(data);
        return {'entityId': Variable.string(id)};
      case 'update':
        final id = data['id'] as String;
        await repository.update(id, data);
        return {};
      case 'delete':
        final id = data['id'] as String;
        await repository.delete(id);
        return {};
      default:
        throw ArgumentError(
          'EntityWorker: unknown operation "$operation"',
        );
    }
  }

  /// Resolves field mappings from task variables.
  ///
  /// Variables prefixed with `field:` are treated as field mappings.
  /// Values starting with `$` are resolved from process variables.
  Map<String, dynamic> _resolveFields(WorkerTask task) {
    final data = <String, dynamic>{};

    for (final entry in task.variables.entries) {
      if (!entry.key.startsWith('field:')) continue;

      final fieldName = entry.key.substring(6);
      final fieldValue = entry.value.value as String;

      if (fieldValue.startsWith(r'$')) {
        final variableName = fieldValue.substring(1);
        final processVar = task.variables[variableName];
        if (processVar != null) {
          data[fieldName] = processVar.value;
        }
      } else {
        data[fieldName] = fieldValue;
      }
    }

    return data;
  }
}
