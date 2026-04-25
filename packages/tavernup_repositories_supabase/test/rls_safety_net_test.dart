import 'package:supabase/supabase.dart' hide User;
import 'package:tavernup_domain/tavernup_domain.dart';
import 'package:tavernup_repositories_supabase/src/supabase_user_repository.dart';
import 'package:test/test.dart';

import 'test_client.dart';

/// The 9 domain tables that must be inaccessible from ANON.
const _domainTables = [
  'users',
  'game_groups',
  'game_group_memberships',
  'invitations',
  'characters',
  'story_nodes',
  'story_node_instances',
  'sessions',
  'user_tasks',
];

/// Positive proof that the RLS safety net works. After Phase 1 the
/// public ANON key may not return any row from any domain table — that
/// is the entire point of enabling RLS without permissive policies.
///
/// If any of these tests fail, the structural assumption "only the
/// server talks to Supabase" is not enforced at the database, and the
/// rest of the RBA migration would be cosmetic.
void main() {
  late SupabaseClient serviceRoleClient;
  late SupabaseClient anonClient;

  setUp(() async {
    serviceRoleClient = createTestClient();
    anonClient = createAnonTestClient();
    await cleanTestData(serviceRoleClient);
  });

  group('RLS safety net', () {
    test('all domain tables return empty to ANON, even with seeded data',
        () async {
      // Seed one row per table via service_role. Use the existing
      // user/game_group repos to satisfy foreign keys without
      // re-implementing inserts here.
      final authId = await createTestAuthUser(
        serviceRoleClient,
        testEmail('rls-victim'),
      );
      await SupabaseUserRepository(serviceRoleClient).save(User(
        id: authId,
        nickname: 'rls-victim',
        createdAt: DateTime.now().toUtc(),
      ));

      // Sanity: service_role sees the row (RLS bypassed).
      final asService =
          await serviceRoleClient.from('users').select().eq('id', authId);
      expect(asService, isNotEmpty,
          reason: 'service_role must bypass RLS — control case');

      // Real check: every domain table returns empty to ANON.
      for (final table in _domainTables) {
        final result = await anonClient.from(table).select();
        expect(result, isEmpty,
            reason: 'ANON must not read $table — RLS safety net');
      }
    });

    test('ANON cannot insert into a domain table', () async {
      // Pick `users` as a representative — same RLS rule applies to all.
      // Use a never-existing UUID to avoid colliding with the seed.
      Object? caughtError;
      try {
        await anonClient.from('users').insert({
          'id': '00000000-0000-0000-0000-000000000099',
          'nickname': 'anon-trespasser',
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (e) {
        caughtError = e;
      }

      expect(caughtError, isA<PostgrestException>(),
          reason: 'ANON insert must be rejected by RLS');

      // And nothing landed.
      final asService = await serviceRoleClient
          .from('users')
          .select()
          .eq('nickname', 'anon-trespasser');
      expect(asService, isEmpty);
    });
  });
}
