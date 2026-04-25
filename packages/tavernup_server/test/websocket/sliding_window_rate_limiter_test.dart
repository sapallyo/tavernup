import 'package:tavernup_server/src/websocket/sliding_window_rate_limiter.dart';
import 'package:test/test.dart';

void main() {
  late DateTime fakeNow;
  late SlidingWindowRateLimiter limiter;

  setUp(() {
    fakeNow = DateTime(2026, 4, 24, 12);
    limiter = SlidingWindowRateLimiter(
      window: const Duration(seconds: 10),
      maxPerWindow: 3,
      now: () => fakeNow,
    );
  });

  test('allows attempts up to the limit', () {
    expect(limiter.allow('ip-1'), isTrue);
    expect(limiter.allow('ip-1'), isTrue);
    expect(limiter.allow('ip-1'), isTrue);
    expect(limiter.allow('ip-1'), isFalse);
  });

  test('per-key buckets are independent', () {
    for (var i = 0; i < 3; i++) limiter.allow('ip-1');
    expect(limiter.allow('ip-1'), isFalse);
    expect(limiter.allow('ip-2'), isTrue);
  });

  test('window expiry frees capacity', () {
    for (var i = 0; i < 3; i++) limiter.allow('ip-1');
    expect(limiter.allow('ip-1'), isFalse);
    fakeNow = fakeNow.add(const Duration(seconds: 11));
    expect(limiter.allow('ip-1'), isTrue);
  });

  test('purge drops empty keys', () {
    limiter.allow('ip-1');
    fakeNow = fakeNow.add(const Duration(seconds: 11));
    limiter.purge();
    // After purge with no fresh hits, the next allow on the same key
    // should still succeed three times — buckets reset.
    expect(limiter.allow('ip-1'), isTrue);
    expect(limiter.allow('ip-1'), isTrue);
    expect(limiter.allow('ip-1'), isTrue);
    expect(limiter.allow('ip-1'), isFalse);
  });
}
