import 'package:equatable/equatable.dart';
import 'stat_modifier.dart';

/// A SR5 character attribute with a base value, a maximum, and
/// a list of active modifiers.
///
/// The [effective] value is what is used for dice rolls — it is
/// the sum of [base] and all active modifiers, clamped to [max].
///
/// Modifiers are keyed by [StatModifier.sourceId] — adding a modifier
/// with an existing source ID replaces the previous one, preventing
/// the same source from stacking with itself.
class Attribute extends Equatable {
  /// The unmodified base value of this attribute.
  final int base;

  /// The metatype maximum for this attribute.
  final int max;

  /// All currently active modifiers on this attribute.
  final List<StatModifier> modifiers;

  const Attribute({
    required this.base,
    required this.max,
    this.modifiers = const [],
  });

  /// The sum of all active modifier values.
  int get totalModifier => modifiers.fold(0, (sum, m) => sum + m.value);

  /// The effective value used for dice rolls.
  ///
  /// Clamped between 0 and [max].
  int get effective => (base + totalModifier).clamp(0, max);

  /// Returns true if the base value has reached the metatype maximum.
  bool get isMaxed => base >= max;

  /// Returns a new attribute with the modifier added.
  ///
  /// If a modifier with the same [StatModifier.sourceId] already exists,
  /// it is replaced.
  Attribute addModifier(StatModifier modifier) {
    final updated = modifiers
        .where((m) => m.sourceId != modifier.sourceId)
        .toList()
      ..add(modifier);
    return Attribute(base: base, max: max, modifiers: updated);
  }

  /// Returns a new attribute with the modifier for [sourceId] removed.
  Attribute removeModifier(String sourceId) {
    return Attribute(
      base: base,
      max: max,
      modifiers: modifiers.where((m) => m.sourceId != sourceId).toList(),
    );
  }

  /// Returns a new attribute with all modifiers of [type] removed.
  Attribute removeModifiersOfType(ModifierType type) {
    return Attribute(
      base: base,
      max: max,
      modifiers: modifiers.where((m) => m.type != type).toList(),
    );
  }

  /// Returns a new attribute with all modifiers cleared.
  Attribute clearModifiers() => Attribute(base: base, max: max);

  /// Returns a new attribute with [base] set to [newBase].
  ///
  /// [newBase] is clamped to [max].
  Attribute withBase(int newBase) => Attribute(
        base: newBase.clamp(0, max),
        max: max,
        modifiers: modifiers,
      );

  factory Attribute.fromJson(Map<String, dynamic> json) {
    return Attribute(
      base: json['base'] as int? ?? 1,
      max: json['max'] as int? ?? 6,
      modifiers: (json['modifiers'] as List? ?? [])
          .map((m) => StatModifier.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'base': base,
        'max': max,
        if (modifiers.isNotEmpty)
          'modifiers': modifiers.map((m) => m.toJson()).toList(),
      };

  Attribute copyWith({
    int? base,
    int? max,
    List<StatModifier>? modifiers,
  }) {
    return Attribute(
      base: base ?? this.base,
      max: max ?? this.max,
      modifiers: modifiers ?? this.modifiers,
    );
  }

  @override
  List<Object?> get props => [base, max, modifiers];

  @override
  String toString() =>
      'Attribute(base: $base, max: $max, effective: $effective, '
      'modifiers: ${modifiers.length})';
}
