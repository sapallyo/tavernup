import 'dart:typed_data';

import 'package:supabase/supabase.dart';
import 'package:tavernup_repositories_supabase/tavernup_repositories_supabase.dart';
import 'package:test/test.dart';

import 'test_client.dart';

/// 1x1 transparent PNG — smallest valid PNG payload, used as test bytes.
final Uint8List _pngBytes = Uint8List.fromList([
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a,
  0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1f, 0x15, 0xc4,
  0x89, 0x00, 0x00, 0x00, 0x0d, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9c, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0d, 0x0a, 0x2d, 0xb4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4e, 0x44, 0xae,
  0x42, 0x60, 0x82,
]);

Future<void> _cleanAvatars(SupabaseClient client) async {
  final files = await client.storage.from('avatars').list();
  for (final folder in files) {
    final inner = await client.storage.from('avatars').list(path: folder.name);
    for (final file in inner) {
      await client.storage
          .from('avatars')
          .remove(['${folder.name}/${file.name}']);
    }
  }
}

void main() {
  late SupabaseClient client;
  late SupabaseUserRepository repository;
  late String authId;

  setUp(() async {
    client = createTestClient();
    repository = SupabaseUserRepository(client);
    await cleanTestData(client);
    await _cleanAvatars(client);
    authId = await createTestAuthUser(client, testEmail('avataruser'));
  });

  group('SupabaseUserRepository.uploadAvatar', () {
    test('returns the userId/avatar path on success', () async {
      final path = await repository.uploadAvatar(
        userId: authId,
        bytes: _pngBytes,
        contentType: 'image/png',
      );
      expect(path, '$authId/avatar');
    });

    test('uploaded bytes round-trip via Storage download', () async {
      await repository.uploadAvatar(
        userId: authId,
        bytes: _pngBytes,
        contentType: 'image/png',
      );

      final downloaded =
          await client.storage.from('avatars').download('$authId/avatar');
      expect(downloaded, _pngBytes);
    });

    test('second upload overwrites the first (no duplicate file)',
        () async {
      await repository.uploadAvatar(
        userId: authId,
        bytes: _pngBytes,
        contentType: 'image/png',
      );

      final newBytes = Uint8List.fromList([..._pngBytes, 0x00]);
      await repository.uploadAvatar(
        userId: authId,
        bytes: newBytes,
        contentType: 'image/png',
      );

      final filesInUserFolder =
          await client.storage.from('avatars').list(path: authId);
      expect(filesInUserFolder, hasLength(1));
      expect(filesInUserFolder.single.name, 'avatar');

      final downloaded =
          await client.storage.from('avatars').download('$authId/avatar');
      expect(downloaded.length, _pngBytes.length + 1);
    });
  });

  group('SupabaseUserRepository.getAvatarSignedUrl', () {
    test('returns a signed URL for an uploaded avatar', () async {
      await repository.uploadAvatar(
        userId: authId,
        bytes: _pngBytes,
        contentType: 'image/png',
      );

      final url =
          await repository.getAvatarSignedUrl(path: '$authId/avatar');
      expect(url, isNotNull);
      expect(url, contains('avatars'));
      expect(url, contains('token='));
    });

    test('returns null for a non-existent path', () async {
      final url = await repository.getAvatarSignedUrl(
        path: 'someone-else/avatar',
      );
      expect(url, isNull);
    });
  });
}
