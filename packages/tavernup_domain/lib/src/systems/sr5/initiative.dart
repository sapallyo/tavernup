import 'package:equatable/equatable.dart';
import 'stat_modifier.dart';

/// The initiative value of a SR5 character.
///
/// Initiative in SR5 is calculated as REA + INT + modifiers,
/// plus a number of d6 dice ([diceCount]). The REA + INT portion
/// is provided externally by the character since it depends on
/// the character's current attribute values.
///
/// Modifiers work the same as on [Attribute] — keyed by sourceId,
/// replacing existing entries with the same source.
class Initiative extends Equatable {
  /// Number of initiative dice (d6) rolled at the start of combat.
  ///
  /// Base is 1 for most characters. Wired Reflexes, Reaction Enhancers
  /// and similar augmentations increase this up to a maximum of 5.
  final int diceCount;

  /// Active modifiers applied to the initiative base value.
  final List<StatModifier> modifiers;

  const Initiative({
    this.diceCount = 1,
    this.modifiers = const [],
  });

  /// The effective initiative base value for a given REA + INT sum.
  ///
  /// The dice roll is added to this at the table — not stored here.
  int effectiveBase(int reactionPlusIntuition) =>
      reactionPlusIntuition + modifiers.fold(0, (sum, m) => sum + m.value);

  /// The sum of all active modifier values.
  int get totalModifier => modifiers.fold(0, (sum, m) => sum + m.value);

  /// Returns a new initiative with the modifier added.
  ///
  /// Replaces any existing modifier with the same sourceId.
  Initiative addModifier(StatModifier modifier) {
    final updated = modifiers
        .where((m) => m.sourceId != modifier.sourceId)
        .toList()
      ..add(modifier);
    return Initiative(diceCount: diceCount, modifiers: updated);
  }

  /// Returns a new initiative with the modifier for [sourceId] removed.
  Initiative removeModifier(String sourceId) {
    return Initiative(
      diceCount: diceCount,
      modifiers: modifiers.where((m) => m.sourceId != sourceId).toList(),
    );
  }

  /// Returns a new initiative with all modifiers of [type] removed.
  Initiative removeModifiersOfType(ModifierType type) {
    return Initiative(
      diceCount: diceCount,
      modifiers: modifiers.where((m) => m.type != type).toList(),
    );
  }

  /// Returns a new initiative with all modifiers cleared.
  Initiative clearModifiers() => Initiative(diceCount: diceCount);

  /// Returns a new initiative with [diceCount] set to [count].
  ///
  /// Clamped between 1 and 5.
  Initiative withDiceCount(int count) => Initiative(
        diceCount: count.clamp(1, 5),
        modifiers: modifiers,
      );

  factory Initiative.fromJson(Map<String, dynamic> json) {
    return Initiative(
      diceCount: json['dice_count'] as int? ?? 1,
      modifiers: (json['modifiers'] as List? ?? [])
          .map((m) => StatModifier.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'dice_count': diceCount,
        if (modifiers.isNotEmpty)
          'modifiers': modifiers.map((m) => m.toJson()).toList(),
      };

  Initiative copyWith({
    int? diceCount,
    List<StatModifier>? modifiers,
  }) {
    return Initiative(
      diceCount: diceCount ?? this.diceCount,
      modifiers: modifiers ?? this.modifiers,
    );
  }

  @override
  List<Object?> get props => [diceCount, modifiers];

  @override
  String toString() =>
      'Initiative(diceCount: $diceCount, totalModifier: $totalModifier)';
}
