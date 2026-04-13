import 'package:test/test.dart';
import 'package:tavernup_domain/tavernup_domain.dart';

void main() {
  group('ResourcePool', () {
    final pool = ResourcePool(max: 5, current: 5);

    group('spend', () {
      test('decreases current', () {
        expect(pool.spend(2).current, 3);
      });

      test('clamps to zero', () {
        expect(pool.spend(10).current, 0);
        expect(pool.spend(10).isEmpty, isTrue);
      });
    });

    group('gain', () {
      test('increases current', () {
        expect(pool.spend(3).gain(2).current, 4);
      });

      test('clamps to max', () {
        expect(pool.spend(3).gain(10).current, 5);
        expect(pool.spend(3).gain(10).isFull, isTrue);
      });
    });

    group('refresh', () {
      test('restores to max', () {
        expect(pool.spend(4).refresh().current, 5);
      });
    });

    group('serialisation', () {
      test('toJson / fromJson roundtrip', () {
        final spent = pool.spend(2);
        final restored = ResourcePool.fromJson(spent.toJson());
        expect(restored, equals(spent));
      });
    });
  });
}
