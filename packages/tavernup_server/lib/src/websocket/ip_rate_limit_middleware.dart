import 'dart:io';

import 'package:shelf/shelf.dart';

import 'sliding_window_rate_limiter.dart';

/// Default per-IP allowance for WebSocket connect attempts.
const int kDefaultIpRateLimitPerWindow = 30;
const Duration kDefaultIpRateLimitWindow = Duration(seconds: 10);

/// Shelf middleware that applies a sliding-window rate limit on the
/// source IP of incoming requests. Intended to wrap the WebSocket
/// upgrade handler — connect floods from a single source are rejected
/// with HTTP 429 before any WebSocket lifecycle starts.
///
/// IP discovery: prefers the leftmost entry of `X-Forwarded-For` (when
/// the server runs behind a proxy that fills it), and falls back to
/// the connection's `remoteAddress` from `shelf_io`. Requests without
/// either are bucketed under the literal key `unknown` so they remain
/// rate-limited as a group.
Middleware ipConnectRateLimit({
  int perWindow = kDefaultIpRateLimitPerWindow,
  Duration window = kDefaultIpRateLimitWindow,
  SlidingWindowRateLimiter? limiter,
}) {
  final activeLimiter = limiter ??
      SlidingWindowRateLimiter(
        window: window,
        maxPerWindow: perWindow,
      );

  return (Handler inner) {
    return (Request request) async {
      final ip = _ipFromRequest(request);
      if (!activeLimiter.allow(ip)) {
        return Response(429, body: 'Too many requests');
      }
      return inner(request);
    };
  };
}

String _ipFromRequest(Request request) {
  final xff = request.headers['x-forwarded-for'];
  if (xff != null && xff.isNotEmpty) {
    final first = xff.split(',').first.trim();
    if (first.isNotEmpty) return first;
  }
  final connInfo =
      request.context['shelf.io.connection_info'] as HttpConnectionInfo?;
  return connInfo?.remoteAddress.address ?? 'unknown';
}
