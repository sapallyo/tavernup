import 'package:test/test.dart';
import 'package:tavernup_domain/tavernup_domain.dart';

void main() {
  group('DamageTrack', () {
    final track = DamageTrack(max: 10, current: 0);

    group('takeDamage', () {
      test('increases current', () {
        expect(track.takeDamage(3).current, 3);
      });

      test('clamps to max', () {
        expect(track.takeDamage(20).current, 10);
      });
    });

    group('heal', () {
      test('decreases current', () {
        expect(track.takeDamage(6).heal(3).current, 3);
      });

      test('clamps to zero', () {
        expect(track.takeDamage(3).heal(10).current, 0);
      });
    });

    group('woundModifier', () {
      test('no damage — no modifier', () {
        expect(track.woundModifier, 0);
      });

      test('3 damage — modifier -1', () {
        expect(track.takeDamage(3).woundModifier, -1);
      });

      test('6 damage — modifier -2', () {
        expect(track.takeDamage(6).woundModifier, -2);
      });

      test('2 damage — modifier 0 (below stepSize)', () {
        expect(track.takeDamage(2).woundModifier, 0);
      });
    });

    group('isIncapacitated', () {
      test('not incapacitated when below max', () {
        expect(track.takeDamage(9).isIncapacitated, isFalse);
      });

      test('incapacitated when at max', () {
        expect(track.takeDamage(10).isIncapacitated, isTrue);
      });
    });

    group('factory constructors', () {
      test('physical track — SR5 formula 8 + ceil(KON/2)', () {
        expect(DamageTrack.physical(4).max, 10);
        expect(DamageTrack.physical(3).max, 10);
        expect(DamageTrack.physical(5).max, 11);
      });

      test('stun track — SR5 formula 8 + ceil(WIL/2)', () {
        expect(DamageTrack.stun(4).max, 10);
        expect(DamageTrack.stun(6).max, 11);
      });
    });

    group('serialisation', () {
      test('toJson / fromJson roundtrip', () {
        final damaged = track.takeDamage(4);
        final restored = DamageTrack.fromJson(damaged.toJson());
        expect(restored, equals(damaged));
      });
    });
  });
}
