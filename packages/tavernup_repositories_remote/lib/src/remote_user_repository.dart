import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:tavernup_domain/tavernup_domain.dart';

/// WebSocket-backed [IUserRepository] for the Flutter client.
///
/// Reads, writes and the avatar-signed-URL helper route through
/// [IRealtimeTransport.request]. The bytes-taking [uploadAvatar] is
/// implemented as a 3-step flow: ask the server for an upload URL,
/// PUT the bytes there, then save the user with the new path. The
/// large binary payload never traverses the WebSocket — see
/// architecture.md "Storage Access".
class RemoteUserRepository implements IUserRepository {
  final IRealtimeTransport _transport;
  final http.Client _http;

  RemoteUserRepository(this._transport, {http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  @override
  Future<User?> getOwn() async {
    final result = (await _transport.request('repo.user.getOwn', {}))['result'];
    return result == null
        ? null
        : User.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<User?> getById(String userId) async {
    final result = (await _transport
        .request('repo.user.getById', {'userId': userId}))['result'];
    return result == null
        ? null
        : User.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<User?> findByNickname(String nickname) async {
    final result = (await _transport
        .request('repo.user.findByNickname', {'nickname': nickname}))['result'];
    return result == null
        ? null
        : User.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<User> save(User user) async {
    final result = (await _transport.request(
        'repo.user.save', {'user': user.toJson()}))['result'];
    return User.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<String?> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    // Step 1 — server-side RBA decides + returns a signed upload URL.
    final issued = (await _transport.request(
        'repo.user.createAvatarUploadUrl',
        {'userId': userId, 'contentType': contentType}))['result']
        as Map<String, dynamic>;
    final uploadUrl = issued['uploadUrl'] as String;
    final path = issued['path'] as String;

    // Step 2 — PUT bytes directly to Storage. Never via WebSocket.
    final response = await _http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': contentType},
      body: bytes,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    // Step 3 — record the path on the user record so subsequent reads
    // produce a signed download URL. Caller's responsibility.
    return path;
  }

  @override
  Future<String?> getAvatarSignedUrl({
    required String path,
    Duration expiresIn = const Duration(hours: 1),
  }) async {
    final result = (await _transport.request(
      'repo.user.getAvatarSignedUrl',
      {'path': path, 'expiresInSeconds': expiresIn.inSeconds},
    ))['result'];
    return result as String?;
  }

  @override
  Future<({String uploadUrl, String path})> createAvatarUploadUrl({
    required String userId,
    required String contentType,
  }) async {
    final result = (await _transport.request(
      'repo.user.createAvatarUploadUrl',
      {'userId': userId, 'contentType': contentType},
    ))['result'] as Map<String, dynamic>;
    return (
      uploadUrl: result['uploadUrl'] as String,
      path: result['path'] as String,
    );
  }
}
