import 'package:equatable/equatable.dart';

/// A finite resource pool with a current value and a maximum.
///
/// Used for Edge in SR5 — a meta-currency that can be spent
/// for advantages during play and refreshed between sessions.
class ResourcePool extends Equatable {
  final int max;
  final int current;

  const ResourcePool({
    required this.max,
    required this.current,
  });

  /// Returns true when the pool is empty.
  bool get isEmpty => current <= 0;

  /// Returns true when the pool is at maximum.
  bool get isFull => current >= max;

  /// The number of points currently available to spend.
  int get available => current;

  /// Returns a new pool with [amount] points spent.
  ResourcePool spend(int amount) {
    assert(amount >= 0, 'amount must be >= 0');
    return ResourcePool(
      max: max,
      current: (current - amount).clamp(0, max),
    );
  }

  /// Returns a new pool with [amount] points gained.
  ResourcePool gain(int amount) {
    assert(amount >= 0, 'amount must be >= 0');
    return ResourcePool(
      max: max,
      current: (current + amount).clamp(0, max),
    );
  }

  /// Returns a new pool with current set directly to [value].
  ResourcePool setDirect(int value) {
    return ResourcePool(
      max: max,
      current: value.clamp(0, max),
    );
  }

  /// Returns a new pool with current restored to [max].
  ///
  /// Called at the end of a session when Edge refreshes.
  ResourcePool refresh() => ResourcePool(max: max, current: max);

  factory ResourcePool.fromJson(Map<String, dynamic> json) {
    return ResourcePool(
      max: json['max'] as int,
      current: json['current'] as int? ?? json['max'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'max': max,
        'current': current,
      };

  ResourcePool copyWith({int? max, int? current}) {
    return ResourcePool(
      max: max ?? this.max,
      current: current ?? this.current,
    );
  }

  @override
  List<Object?> get props => [max, current];
}
