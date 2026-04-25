import 'dart:typed_data';

import 'package:tavernup_domain/tavernup_domain.dart';

import '../principal.dart';

/// Authorizing wrapper around a raw [IUserRepository].
///
/// Read methods (`getOwn`, `getById`, `findByNickname`) project the
/// stored avatar path through `getAvatarSignedUrl` so the returned
/// [User] carries a freshly signed download URL in `avatarUrl` rather
/// than the bare Storage key. This is the avatar-download half of the
/// signed-URL flow described in architecture.md "Storage Access".
///
/// Filter and per-principal projection beyond avatar substitution is
/// pass-through for now — full role-aware checks land with the role
/// catalog work.
class UserRepositoryWrapper implements IUserRepository {
  final IUserRepository _raw;
  // ignore: unused_field
  final Principal _principal;

  UserRepositoryWrapper(this._raw, this._principal);

  @override
  Future<User?> getOwn() async => _projectAvatar(await _raw.getOwn());

  @override
  Future<User?> getById(String userId) async =>
      _projectAvatar(await _raw.getById(userId));

  @override
  Future<User?> findByNickname(String nickname) async =>
      _projectAvatar(await _raw.findByNickname(nickname));

  @override
  Future<User> save(User user) => _raw.save(user);

  @override
  Future<String?> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String contentType,
  }) =>
      _raw.uploadAvatar(
        userId: userId,
        bytes: bytes,
        contentType: contentType,
      );

  @override
  Future<String?> getAvatarSignedUrl({
    required String path,
    Duration expiresIn = const Duration(hours: 1),
  }) =>
      _raw.getAvatarSignedUrl(path: path, expiresIn: expiresIn);

  @override
  Future<({String uploadUrl, String path})> createAvatarUploadUrl({
    required String userId,
    required String contentType,
  }) =>
      _raw.createAvatarUploadUrl(userId: userId, contentType: contentType);

  /// Replaces the stored avatar path with a freshly signed download URL.
  /// Null avatar → null result (field stays absent in the projection).
  /// Path that no longer resolves (Storage missing, signing fails) → the
  /// avatarUrl is cleared so callers don't render a broken link.
  Future<User?> _projectAvatar(User? user) async {
    if (user == null || user.avatarUrl == null) return user;
    final url = await _raw.getAvatarSignedUrl(path: user.avatarUrl!);
    return user.copyWith(
      avatarUrl: url,
      clearAvatar: url == null,
    );
  }
}
