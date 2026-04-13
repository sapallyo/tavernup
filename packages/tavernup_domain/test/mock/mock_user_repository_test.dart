import 'package:test/test.dart';
import 'package:tavernup_domain/tavernup_domain.dart';

void main() {
  group('MockUserRepository', () {
    late MockUserRepository repo;

    final user1 = User(
      id: 'user-1',
      nickname: 'Shadowrunner',
      createdAt: DateTime(2024, 1, 15),
    );
    final user2 = User(
      id: 'user-2',
      nickname: 'Ghost',
      createdAt: DateTime(2024, 1, 15),
    );

    setUp(() {
      repo = MockUserRepository();
      repo.seed([user1, user2], currentUserId: 'user-1');
    });

    test('getOwn returns current user', () async {
      expect(await repo.getOwn(), equals(user1));
    });

    test('getOwn returns null when no current user', () async {
      final empty = MockUserRepository();
      expect(await empty.getOwn(), isNull);
    });

    test('getById returns correct user', () async {
      expect(await repo.getById('user-2'), equals(user2));
    });

    test('getById returns null for unknown id', () async {
      expect(await repo.getById('unknown'), isNull);
    });

    test('findByNickname returns correct user', () async {
      expect(await repo.findByNickname('Ghost'), equals(user2));
    });

    test('findByNickname returns null for unknown nickname', () async {
      expect(await repo.findByNickname('Unknown'), isNull);
    });

    test('save stores and returns user', () async {
      final newUser = User(
        id: 'user-3',
        nickname: 'Razor',
        createdAt: DateTime(2024, 1, 15),
      );
      final saved = await repo.save(newUser);
      expect(saved, equals(newUser));
      expect(await repo.getById('user-3'), equals(newUser));
    });

    test('save updates existing user', () async {
      final updated = user1.copyWith(nickname: 'NewName');
      await repo.save(updated);
      expect((await repo.getById('user-1'))?.nickname, 'NewName');
    });
  });
}
