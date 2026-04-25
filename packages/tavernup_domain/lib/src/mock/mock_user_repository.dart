import 'dart:typed_data';

import '../models/user.dart';
import '../repositories/i_user_repository.dart';

/// In-memory implementation of [IUserRepository] for testing.
///
/// All data is stored in a simple map and lost when the instance
/// is discarded. No network calls, no side effects.
class MockUserRepository implements IUserRepository {
  final Map<String, User> _store = {};
  String? _currentUserId;

  /// Seeds the repository with initial data.
  void seed(List<User> users, {String? currentUserId}) {
    for (final u in users) {
      _store[u.id] = u;
    }
    _currentUserId = currentUserId;
  }

  @override
  Future<User?> getOwn() async =>
      _currentUserId != null ? _store[_currentUserId] : null;

  @override
  Future<User?> getById(String userId) async => _store[userId];

  @override
  Future<User?> findByNickname(String nickname) async {
    try {
      return _store.values.firstWhere((u) => u.nickname == nickname);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<User> save(User user) async {
    _store[user.id] = user;
    return user;
  }

  /// Recorded avatar uploads, keyed by userId — for test assertions.
  final Map<String, ({Uint8List bytes, String contentType})>
      uploadedAvatars = {};

  @override
  Future<String?> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    uploadedAvatars[userId] = (bytes: bytes, contentType: contentType);
    return '$userId/avatar';
  }

  @override
  Future<String?> getAvatarSignedUrl({
    required String path,
    Duration expiresIn = const Duration(hours: 1),
  }) async {
    final userId = path.split('/').first;
    if (!uploadedAvatars.containsKey(userId)) return null;
    return 'mock://signed/$path?expires=${expiresIn.inSeconds}';
  }
}
