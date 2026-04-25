import 'package:supabase/supabase.dart' hide User;
import 'package:tavernup_domain/tavernup_domain.dart';
import 'package:tavernup_repositories_supabase/src/supabase_sync_service.dart';
import 'package:tavernup_repositories_supabase/src/supabase_user_repository.dart';
import 'package:test/test.dart';

import 'test_client.dart';

/// Polls [check] until it returns true or the [timeout] elapses.
///
/// Used to wait for asynchronous events from Supabase Realtime to arrive
/// into a collector list maintained by a [StreamSubscription.listen].
Future<void> _awaitCondition(
  bool Function() check, {
  Duration timeout = const Duration(seconds: 10),
  Duration interval = const Duration(milliseconds: 50),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!check() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(interval);
  }
  if (!check()) {
    throw StateError('Condition not met within $timeout');
  }
}

void main() {
  late SupabaseClient client;
  late SupabaseSyncService syncService;

  setUp(() async {
    client = createTestClient();
    syncService = SupabaseSyncService(client);
    await cleanTestData(client);
  });

  group('SupabaseSyncService', () {
    test('watchById emits current state and subsequent updates', () async {
      final authId = await createTestAuthUser(client, testEmail('updateme'));
      final userRepo = SupabaseUserRepository(client);
      await userRepo.save(User(
        id: authId,
        nickname: 'before',
        createdAt: DateTime.now().toUtc(),
      ));

      final emissions = <User>[];
      final sub = syncService
          .watchById<User>('users', authId, fromJson: User.fromJson)
          .listen(emissions.add);

      try {
        await _awaitCondition(
          () => emissions.any((u) => u.nickname == 'before'),
        );

        await client
            .from('users')
            .update({'nickname': 'after'}).eq('id', authId);

        await _awaitCondition(
          () => emissions.any((u) => u.nickname == 'after'),
        );
      } finally {
        await sub.cancel().timeout(
              const Duration(seconds: 2),
              onTimeout: () {},
            );
      }
      expect(
        emissions.map((u) => u.nickname),
        containsAll(['before', 'after']),
      );
    });

    test('watchById completes when row is deleted', () async {
      final authId = await createTestAuthUser(client, testEmail('deleteme'));
      final userRepo = SupabaseUserRepository(client);
      await userRepo.save(User(
        id: authId,
        nickname: 'deleteme',
        createdAt: DateTime.now().toUtc(),
      ));

      var initialReceived = false;
      var completed = false;
      final sub = syncService
          .watchById<User>('users', authId, fromJson: User.fromJson)
          .listen(
        (_) => initialReceived = true,
        onDone: () => completed = true,
      );

      await _awaitCondition(() => initialReceived);

      await client.from('users').delete().eq('id', authId);
      await deleteTestAuthUser(client, authId);

      await _awaitCondition(() => completed);
      await sub.cancel();
    });

    test('watchWhere emits list filtered by field', () async {
      final aliceId = await createTestAuthUser(client, testEmail('alice'));
      final bobId = await createTestAuthUser(client, testEmail('bob'));
      final userRepo = SupabaseUserRepository(client);
      await userRepo.save(User(
        id: aliceId,
        nickname: 'alice',
        createdAt: DateTime.now().toUtc(),
      ));
      await userRepo.save(User(
        id: bobId,
        nickname: 'bob',
        createdAt: DateTime.now().toUtc(),
      ));

      final emissions = <List<User>>[];
      final sub = syncService
          .watchWhere<User>(
            'users',
            field: 'nickname',
            value: 'alice',
            fromJson: User.fromJson,
          )
          .listen(emissions.add);

      await _awaitCondition(
        () => emissions.any((list) => list.any((u) => u.id == aliceId)),
      );

      await sub.cancel();
      final lastMatching =
          emissions.lastWhere((list) => list.any((u) => u.id == aliceId));
      expect(lastMatching.map((u) => u.nickname), ['alice']);
    });

    test('watchWhere reflects newly inserted matching row', () async {
      final emissions = <List<User>>[];
      final sub = syncService
          .watchWhere<User>(
            'users',
            field: 'nickname',
            value: 'newbie',
            fromJson: User.fromJson,
          )
          .listen(emissions.add);

      // Allow the realtime subscription to settle before the insert.
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final authId = await createTestAuthUser(client, testEmail('newbie'));
      final userRepo = SupabaseUserRepository(client);
      await userRepo.save(User(
        id: authId,
        nickname: 'newbie',
        createdAt: DateTime.now().toUtc(),
      ));

      await _awaitCondition(
        () => emissions.any((list) => list.any((u) => u.id == authId)),
      );

      await sub.cancel();
    });
  });
}
