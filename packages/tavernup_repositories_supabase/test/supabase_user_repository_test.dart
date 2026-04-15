import 'package:supabase/supabase.dart' hide User;
import 'package:tavernup_domain/tavernup_domain.dart';
import 'package:tavernup_repositories_supabase/tavernup_repositories_supabase.dart';
import 'package:test/test.dart';

import 'test_client.dart';

void main() {
  late SupabaseClient client;
  late SupabaseUserRepository repository;

  setUp(() {
    client = createTestClient();
    repository = SupabaseUserRepository(client);
  });

  tearDown(() async {
    await client
        .from('users')
        .delete()
        .neq('id', '00000000-0000-0000-0000-000000000000');
  });

  group('SupabaseUserRepository', () {
    test('save and getById round-trip', () async {
      final authId = await createTestAuthUser(client, 'testuser@test.local');
      addTearDown(() => deleteTestAuthUser(client, authId));

      final user = User(
        id: authId,
        nickname: 'testuser',
        createdAt: DateTime.now().toUtc(),
      );

      await repository.save(user);
      final loaded = await repository.getById(user.id);

      expect(loaded, isNotNull);
      expect(loaded!.id, equals(user.id));
      expect(loaded.nickname, equals(user.nickname));
    });

    test('findByNickname returns correct user', () async {
      final authId = await createTestAuthUser(client, 'findme@test.local');
      addTearDown(() => deleteTestAuthUser(client, authId));

      final user = User(
        id: authId,
        nickname: 'findme',
        createdAt: DateTime.now().toUtc(),
      );

      await repository.save(user);
      final found = await repository.findByNickname('findme');

      expect(found, isNotNull);
      expect(found!.id, equals(user.id));
    });

    test('findByNickname returns null for unknown nickname', () async {
      final result = await repository.findByNickname('doesnotexist');
      expect(result, isNull);
    });

    test('getById returns null for unknown id', () async {
      final result =
          await repository.getById('00000000-0000-0000-0000-000000000099');
      expect(result, isNull);
    });

    test('save without valid auth id throws', () async {
      final user = User(
        id: '00000000-0000-0000-0000-000000000001',
        nickname: 'ghost',
        createdAt: DateTime.now().toUtc(),
      );

      expect(() => repository.save(user), throwsA(isA<PostgrestException>()));
    });
  });
}
