import 'package:test/test.dart';
import 'package:tavernup_domain/tavernup_domain.dart';

void main() {
  group('AdventureCharacter', () {
    final ac = AdventureCharacter(
      id: 'ac-1',
      userId: 'user-1',
      characterId: 'char-1',
      addedAt: DateTime(2024, 1, 15),
    );

    group('serialisation', () {
      test('toJson contains userId and characterId', () {
        final json = ac.toJson();
        expect(json['user_id'], 'user-1');
        expect(json['character_id'], 'char-1');
        expect(json.containsKey('role_override'), isFalse);
      });

      test('toJson includes roleOverride when set', () {
        final withRole = AdventureCharacter(
          id: 'ac-2',
          userId: 'user-1',
          characterId: 'char-1',
          roleOverride: CharacterRoleOverride.pc,
          addedAt: DateTime(2024, 1, 15),
        );
        expect(withRole.toJson()['role_override'], 'pc');
      });

      test('fromJson roundtrip', () {
        final json = {
          'id': 'ac-1',
          'user_id': 'user-1',
          'character_id': 'char-1',
          'added_at': '2024-01-15T00:00:00.000',
        };
        final restored = AdventureCharacter.fromJson(json);
        expect(restored.userId, 'user-1');
        expect(restored.roleOverride, isNull);
      });
    });

    group('CharacterRoleOverride', () {
      test('fromString parses pc and npc', () {
        expect(
            CharacterRoleOverride.fromString('pc'), CharacterRoleOverride.pc);
        expect(
            CharacterRoleOverride.fromString('npc'), CharacterRoleOverride.npc);
      });

      test('fromString defaults to npc for unknown value', () {
        expect(CharacterRoleOverride.fromString('unknown'),
            CharacterRoleOverride.npc);
      });
    });
  });
}
