import 'dart:collection';

/// In-memory sliding-window rate limiter keyed by an arbitrary string
/// (typically the source IP).
///
/// Used to cap WebSocket connect attempts per IP. Stores per-key the
/// recent timestamps within `window`; on each [allow] call drops
/// expired entries and rejects if the remaining list is at or above
/// `maxPerWindow`.
///
/// Memory is unbounded across keys — a busy server seeing many distinct
/// IPs accumulates one [Queue] per IP. For the expected scale this is
/// acceptable. If it ever isn't, schedule periodic [purge].
class SlidingWindowRateLimiter {
  final Duration window;
  final int maxPerWindow;
  final DateTime Function() _now;

  final Map<String, Queue<DateTime>> _hits = {};

  SlidingWindowRateLimiter({
    required this.window,
    required this.maxPerWindow,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Records an attempt for [key] and returns true if it is allowed.
  bool allow(String key) {
    final now = _now();
    final cutoff = now.subtract(window);
    final hits = _hits.putIfAbsent(key, () => Queue<DateTime>());
    while (hits.isNotEmpty && !hits.first.isAfter(cutoff)) {
      hits.removeFirst();
    }
    if (hits.length >= maxPerWindow) return false;
    hits.add(now);
    return true;
  }

  /// Removes entries whose latest hit is older than `window` so empty
  /// keys stop occupying memory. Optional, intended for periodic
  /// scheduling on long-running servers.
  void purge() {
    final cutoff = _now().subtract(window);
    _hits.removeWhere((_, hits) {
      while (hits.isNotEmpty && !hits.first.isAfter(cutoff)) {
        hits.removeFirst();
      }
      return hits.isEmpty;
    });
  }
}
