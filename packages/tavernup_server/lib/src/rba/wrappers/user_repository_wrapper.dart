import 'dart:typed_data';

import 'package:tavernup_domain/tavernup_domain.dart';

import '../principal.dart';

/// Authorizing wrapper around a raw [IUserRepository].
///
/// Currently pass-through: every call delegates to the raw repository
/// regardless of the principal. Filter and projection logic per
/// principal will be added when the role catalog is filled in.
class UserRepositoryWrapper implements IUserRepository {
  final IUserRepository _raw;
  // ignore: unused_field
  final Principal _principal;

  UserRepositoryWrapper(this._raw, this._principal);

  @override
  Future<User?> getOwn() => _raw.getOwn();

  @override
  Future<User?> getById(String userId) => _raw.getById(userId);

  @override
  Future<User?> findByNickname(String nickname) =>
      _raw.findByNickname(nickname);

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
}
