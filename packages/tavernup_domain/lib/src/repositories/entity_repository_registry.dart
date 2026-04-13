import 'package:tavernup_domain/tavernup_domain.dart';

/// Concrete implementation of [IEntityRegistry].
///
/// Repositories are registered at startup and looked up by entity type
/// string during worker task processing.
class EntityRegistry {
  final Map<String, IEntityRepository> _repositories = {};

  void register(IEntityRepository repository) {
    _repositories[repository.entityType] = repository;
  }

  IEntityRepository findByType(String entityType) {
    final repository = _repositories[entityType];
    if (repository == null) {
      throw ArgumentError(
        'No repository registered for entity type: $entityType',
      );
    }
    return repository;
  }

  List<String> get registeredTypes => _repositories.keys.toList();
}
