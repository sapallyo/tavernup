import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:tavernup_server/src/websocket/ip_rate_limit_middleware.dart';
import 'package:tavernup_server/src/websocket/sliding_window_rate_limiter.dart';

Handler _passthrough(Middleware middleware) {
  return middleware((req) async => Response.ok('ok'));
}

Request _request({String? xForwardedFor}) {
  return Request(
    'GET',
    Uri.parse('http://localhost:8080/ws'),
    headers: {
      if (xForwardedFor != null) 'x-forwarded-for': xForwardedFor,
    },
  );
}

void main() {
  test('honours X-Forwarded-For for IP discovery', () async {
    DateTime fake = DateTime(2026, 4, 24, 12);
    final limiter = SlidingWindowRateLimiter(
      window: const Duration(seconds: 10),
      maxPerWindow: 2,
      now: () => fake,
    );
    final handler =
        _passthrough(ipConnectRateLimit(limiter: limiter));

    expect(
        (await handler(_request(xForwardedFor: '1.2.3.4'))).statusCode, 200);
    expect(
        (await handler(_request(xForwardedFor: '1.2.3.4'))).statusCode, 200);
    expect(
        (await handler(_request(xForwardedFor: '1.2.3.4'))).statusCode, 429);

    // Different IP gets its own bucket.
    expect(
        (await handler(_request(xForwardedFor: '5.6.7.8'))).statusCode, 200);
  });

  test('uses leftmost XFF entry when chain has multiple proxies',
      () async {
    DateTime fake = DateTime(2026, 4, 24, 12);
    final limiter = SlidingWindowRateLimiter(
      window: const Duration(seconds: 10),
      maxPerWindow: 1,
      now: () => fake,
    );
    final handler =
        _passthrough(ipConnectRateLimit(limiter: limiter));

    expect(
        (await handler(_request(xForwardedFor: '1.2.3.4, 9.9.9.9')))
            .statusCode,
        200);
    expect(
        (await handler(_request(xForwardedFor: '1.2.3.4, 9.9.9.9')))
            .statusCode,
        429);
    // Same trailing proxy, different leftmost client → independent bucket.
    expect(
        (await handler(_request(xForwardedFor: '7.7.7.7, 9.9.9.9')))
            .statusCode,
        200);
  });

  test('falls back to "unknown" bucket when IP cannot be resolved',
      () async {
    DateTime fake = DateTime(2026, 4, 24, 12);
    final limiter = SlidingWindowRateLimiter(
      window: const Duration(seconds: 10),
      maxPerWindow: 2,
      now: () => fake,
    );
    final handler =
        _passthrough(ipConnectRateLimit(limiter: limiter));

    expect((await handler(_request())).statusCode, 200);
    expect((await handler(_request())).statusCode, 200);
    expect((await handler(_request())).statusCode, 429);
  });
}
