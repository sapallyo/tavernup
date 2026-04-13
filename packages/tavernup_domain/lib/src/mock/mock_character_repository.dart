import '../models/character.dart';
import '../repositories/i_character_repository.dart';

/// In-memory implementation of [ICharacterRepository] for testing.
class MockCharacterRepository implements ICharacterRepository {
  final Map<String, Character> _store = {};

  void seed(List<Character> characters) {
    for (final c in characters) {
      _store[c.id] = c;
    }
  }

  @override
  Future<List<Character>> getOwned(String ownerId) async =>
      _store.values.where((c) => c.ownerId == ownerId).toList();

  @override
  Future<List<Character>> getVisible(String userId) async => _store.values
      .where((c) => c.ownerId == userId || c.visibleFor.contains(userId))
      .toList();

  @override
  Future<Character?> getById(String id) async => _store[id];

  @override
  Future<void> save(Character character) async {
    _store[character.id] = character;
  }

  @override
  Future<void> delete(String id) async => _store.remove(id);

  @override
  Future<void> grantVisibility(String characterId, String userId) async {
    final character = _store[characterId];
    if (character == null) return;
    if (!character.visibleFor.contains(userId)) {
      _store[characterId] = character.copyWith(
        visibleFor: [...character.visibleFor, userId],
      );
    }
  }

  @override
  Future<void> revokeVisibility(String characterId, String userId) async {
    final character = _store[characterId];
    if (character == null) return;
    _store[characterId] = character.copyWith(
      visibleFor: character.visibleFor.where((id) => id != userId).toList(),
    );
  }

  @override
  Stream<List<Character>> watchOwned(String ownerId) =>
      Stream.value(_store.values.where((c) => c.ownerId == ownerId).toList());
}
