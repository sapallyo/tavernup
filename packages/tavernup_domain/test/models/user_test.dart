import 'package:test/test.dart';
import 'package:tavernup_domain/tavernup_domain.dart';

void main() {
  group('User', () {
    final testUser = User(
      id: 'user-1',
      nickname: 'Shadowrunner',
      avatarUrl: 'https://example.com/avatar.png',
      createdAt: DateTime(2024, 1, 15),
    );

    group('serialisation', () {
      test('toJson contains all fields', () {
        final json = testUser.toJson();
        expect(json['id'], 'user-1');
        expect(json['nickname'], 'Shadowrunner');
        expect(json['avatar_url'], 'https://example.com/avatar.png');
      });

      test('fromJson roundtrip', () {
        final json = {
          'id': 'user-1',
          'nickname': 'Shadowrunner',
          'avatar_url': 'https://example.com/avatar.png',
          'created_at': '2024-01-15T00:00:00.000',
        };
        final user = User.fromJson(json);
        expect(user.id, 'user-1');
        expect(user.nickname, 'Shadowrunner');
        expect(user.avatarUrl, 'https://example.com/avatar.png');
      });

      test('toJson omits null avatarUrl', () {
        final user = User(
          id: 'user-2',
          nickname: 'Ghost',
          createdAt: DateTime(2024, 1, 15),
        );
        expect(user.toJson().containsKey('avatar_url'), isFalse);
      });
    });

    group('copyWith', () {
      test('updates nickname', () {
        final updated = testUser.copyWith(nickname: 'NewName');
        expect(updated.nickname, 'NewName');
        expect(updated.id, testUser.id);
      });

      test('clearAvatar sets avatarUrl to null', () {
        final updated = testUser.copyWith(clearAvatar: true);
        expect(updated.avatarUrl, isNull);
      });
    });

    group('equality', () {
      test('same fields are equal', () {
        final user2 = User(
          id: 'user-1',
          nickname: 'Shadowrunner',
          avatarUrl: 'https://example.com/avatar.png',
          createdAt: DateTime(2024, 1, 15),
        );
        expect(testUser, equals(user2));
      });

      test('different id are not equal', () {
        testUser.copyWith();
        final user3 = User(
          id: 'user-2',
          nickname: 'Shadowrunner',
          avatarUrl: 'https://example.com/avatar.png',
          createdAt: DateTime(2024, 1, 15),
        );
        expect(testUser, isNot(equals(user3)));
      });
    });
  });
}
