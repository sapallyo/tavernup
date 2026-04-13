import 'package:equatable/equatable.dart';

/// A SR5 damage monitor tracking physical or stun damage.
///
/// The monitor has a [max] capacity and a [current] damage value.
/// When [current] reaches [max] the character is [isIncapacitated].
///
/// Wound modifiers are applied as penalties to dice pools:
/// every [stepSize] points of damage incur a -1 penalty.
class DamageTrack extends Equatable {
  /// Maximum capacity of this damage monitor.
  final int max;

  /// Current damage recorded on this monitor.
  final int current;

  /// Number of damage boxes per wound modifier step.
  ///
  /// SR5 default is 3 — every 3 boxes of damage incur a -1 penalty.
  final int stepSize;

  const DamageTrack({
    required this.max,
    required this.current,
    this.stepSize = 3,
  });

  /// The wound modifier penalty from this track.
  ///
  /// Always zero or negative. Applied to all dice pools.
  int get woundModifier => -(current ~/ stepSize);

  /// Returns true when the monitor is full and the character is down.
  bool get isIncapacitated => current >= max;

  /// Number of damage boxes still available.
  int get remaining => max - current;

  /// Returns a new track with [amount] damage added.
  DamageTrack takeDamage(int amount) {
    assert(amount >= 0, 'amount must be >= 0');
    return DamageTrack(
      max: max,
      current: (current + amount).clamp(0, max),
      stepSize: stepSize,
    );
  }

  /// Returns a new track with [amount] damage healed.
  DamageTrack heal(int amount) {
    assert(amount >= 0, 'amount must be >= 0');
    return DamageTrack(
      max: max,
      current: (current - amount).clamp(0, max),
      stepSize: stepSize,
    );
  }

  /// Returns a new track with damage set directly to [value].
  DamageTrack setDirect(int value) {
    return DamageTrack(
      max: max,
      current: value.clamp(0, max),
      stepSize: stepSize,
    );
  }

  /// Creates a physical damage track sized for a character
  /// with [constitution] as their Konstitution attribute value.
  ///
  /// SR5 formula: 8 + ceil(KON / 2)
  factory DamageTrack.physical(int constitution, {int stepSize = 3}) {
    return DamageTrack(
      max: 8 + (constitution / 2).ceil(),
      current: 0,
      stepSize: stepSize,
    );
  }

  /// Creates a stun damage track sized for a character
  /// with [willpower] as their Willensstärke attribute value.
  ///
  /// SR5 formula: 8 + ceil(WIL / 2)
  factory DamageTrack.stun(int willpower, {int stepSize = 3}) {
    return DamageTrack(
      max: 8 + (willpower / 2).ceil(),
      current: 0,
      stepSize: stepSize,
    );
  }

  factory DamageTrack.fromJson(Map<String, dynamic> json) {
    return DamageTrack(
      max: json['max'] as int,
      current: json['current'] as int? ?? 0,
      stepSize: json['step_size'] as int? ?? 3,
    );
  }

  Map<String, dynamic> toJson() => {
        'max': max,
        'current': current,
        'step_size': stepSize,
      };

  DamageTrack copyWith({int? max, int? current, int? stepSize}) {
    return DamageTrack(
      max: max ?? this.max,
      current: current ?? this.current,
      stepSize: stepSize ?? this.stepSize,
    );
  }

  @override
  List<Object?> get props => [max, current, stepSize];
}
