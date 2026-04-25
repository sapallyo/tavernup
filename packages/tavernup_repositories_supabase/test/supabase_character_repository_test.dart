import 'package:supabase/supabase.dart' hide User;
import 'package:tavernup_domain/tavernup_domain.dart';
import 'package:tavernup_repositories_supabase/src/supabase_character_repository.dart';
import 'package:test/test.dart';

import 'test_client.dart';

void main() {
  late SupabaseClient client;
  late SupabaseCharacterRepository repository;

  setUp(() async {
    client = createTestClient();
    repository = SupabaseCharacterRepository(client);
    await cleanTestData(client);
  });

  Future<String> setupAuthAndDomainUser(String name) async {
    final authId = await createTestAuthUser(client, testEmail(name));
    await client.from('users').insert({
      'id': authId,
      'nickname': name,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    return authId;
  }

  Character buildCharacter(
      {required String ownerId, String name = 'Test Character'}) {
    return Character(
      id: '00000000-0000-0000-${ownerId.substring(0, 4)}-${DateTime.now().millisecondsSinceEpoch.toString().padLeft(12, '0').substring(0, 12)}',
      ownerId: ownerId,
      name: name,
      systemKey: 'sr5',
    );
  }

  group('SupabaseCharacterRepository', () {
    test('save and getById round-trip', () async {
      final ownerId = await setupAuthAndDomainUser('owner');
      final character = buildCharacter(ownerId: ownerId);

      await repository.save(character);
      final loaded = await repository.getById(character.id);

      expect(loaded, isNotNull);
      expect(loaded!.id, equals(character.id));
      expect(loaded.name, equals(character.name));
      expect(loaded.ownerId, equals(ownerId));
    });

    test('getOwned returns only characters of owner', () async {
      final owner1 = await setupAuthAndDomainUser('owner1');
      final owner2 = await setupAuthAndDomainUser('owner2');

      final c1 = buildCharacter(ownerId: owner1, name: 'Character A');
      final c2 = buildCharacter(ownerId: owner2, name: 'Character B');

      await repository.save(c1);
      await repository.save(c2);

      final owned = await repository.getOwned(owner1);
      expect(owned.map((c) => c.id), contains(c1.id));
      expect(owned.map((c) => c.id), isNot(contains(c2.id)));
    });

    test('grantVisibility allows other user to see character', () async {
      final owner = await setupAuthAndDomainUser('owner');
      final viewer = await setupAuthAndDomainUser('viewer');

      final character = buildCharacter(ownerId: owner);
      await repository.save(character);

      await repository.grantVisibility(character.id, viewer);

      final visible = await repository.getVisible(viewer);
      expect(visible.map((c) => c.id), contains(character.id));
    });

    test('revokeVisibility removes other user from visible list', () async {
      final owner = await setupAuthAndDomainUser('owner');
      final viewer = await setupAuthAndDomainUser('viewer');

      final character = buildCharacter(ownerId: owner);
      await repository.save(character);

      await repository.grantVisibility(character.id, viewer);
      await repository.revokeVisibility(character.id, viewer);

      final visible = await repository.getVisible(viewer);
      expect(visible.map((c) => c.id), isNot(contains(character.id)));
    });

    test('getVisible returns own characters', () async {
      final owner = await setupAuthAndDomainUser('owner');
      final character = buildCharacter(ownerId: owner);
      await repository.save(character);

      final visible = await repository.getVisible(owner);
      expect(visible.map((c) => c.id), contains(character.id));
    });

    test('delete removes character', () async {
      final owner = await setupAuthAndDomainUser('owner');
      final character = buildCharacter(ownerId: owner);
      await repository.save(character);

      await repository.delete(character.id);
      final loaded = await repository.getById(character.id);

      expect(loaded, isNull);
    });
  });
}
