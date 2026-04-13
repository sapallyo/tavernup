import 'package:test/test.dart';
import 'package:tavernup_domain/tavernup_domain.dart';

void main() {
  group('MockCharacterRepository', () {
    late MockCharacterRepository repo;

    final char1 = Character(
      id: 'char-1',
      ownerId: 'user-1',
      name: 'Serena Ashford',
      systemKey: 'sr5',
    );
    final char2 = Character(
      id: 'char-2',
      ownerId: 'user-2',
      name: 'Ghost',
      systemKey: 'sr5',
    );

    setUp(() {
      repo = MockCharacterRepository();
      repo.seed([char1, char2]);
    });

    test('getOwned returns only owned characters', () async {
      final owned = await repo.getOwned('user-1');
      expect(owned.length, 1);
      expect(owned.first.id, 'char-1');
    });

    test('getVisible returns owned and visible characters', () async {
      await repo.grantVisibility('char-2', 'user-1');
      final visible = await repo.getVisible('user-1');
      expect(visible.length, 2);
    });

    test('getById returns correct character', () async {
      expect(await repo.getById('char-1'), equals(char1));
    });

    test('save stores character', () async {
      final newChar = Character(
        id: 'char-3',
        ownerId: 'user-1',
        name: 'Lena Fischer',
        systemKey: 'sr5',
      );
      await repo.save(newChar);
      expect(await repo.getById('char-3'), equals(newChar));
    });

    test('delete removes character', () async {
      await repo.delete('char-1');
      expect(await repo.getById('char-1'), isNull);
    });

    test('grantVisibility adds userId to visibleFor', () async {
      await repo.grantVisibility('char-2', 'user-1');
      final char = await repo.getById('char-2');
      expect(char?.visibleFor, contains('user-1'));
    });

    test('grantVisibility does not duplicate', () async {
      await repo.grantVisibility('char-2', 'user-1');
      await repo.grantVisibility('char-2', 'user-1');
      final char = await repo.getById('char-2');
      expect(char?.visibleFor.where((id) => id == 'user-1').length, 1);
    });

    test('revokeVisibility removes userId from visibleFor', () async {
      await repo.grantVisibility('char-2', 'user-1');
      await repo.revokeVisibility('char-2', 'user-1');
      final char = await repo.getById('char-2');
      expect(char?.visibleFor, isNot(contains('user-1')));
    });

    test('watchOwned emits owned characters', () async {
      final stream = repo.watchOwned('user-1');
      final result = await stream.first;
      expect(result.length, 1);
      expect(result.first.id, 'char-1');
    });
  });
}
