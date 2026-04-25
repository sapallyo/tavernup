import 'package:tavernup_domain/tavernup_domain.dart';

import '../principal.dart';

/// Authorizing wrapper around a raw [ICharacterRepository].
///
/// Currently pass-through: every call delegates to the raw repository
/// regardless of the principal. Filter and projection logic per
/// principal will be added when the role catalog is filled in.
class CharacterRepositoryWrapper implements ICharacterRepository {
  final ICharacterRepository _raw;
  // ignore: unused_field
  final Principal _principal;

  CharacterRepositoryWrapper(this._raw, this._principal);

  @override
  Future<List<Character>> getOwned(String ownerId) => _raw.getOwned(ownerId);

  @override
  Future<List<Character>> getVisible(String userId) => _raw.getVisible(userId);

  @override
  Future<Character?> getById(String id) => _raw.getById(id);

  @override
  Future<void> save(Character character) => _raw.save(character);

  @override
  Future<void> delete(String id) => _raw.delete(id);

  @override
  Future<void> grantVisibility(String characterId, String userId) =>
      _raw.grantVisibility(characterId, userId);

  @override
  Future<void> revokeVisibility(String characterId, String userId) =>
      _raw.revokeVisibility(characterId, userId);

  @override
  Stream<List<Character>> watchOwned(String ownerId) =>
      _raw.watchOwned(ownerId);
}
