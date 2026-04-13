import 'package:equatable/equatable.dart';

/// The source category of a stat modifier.
///
/// Used to group and selectively remove modifiers —
/// for example removing all [wound] modifiers after healing,
/// or all [spell] modifiers when a spell expires.
enum ModifierType {
  spell,
  adeptPower,
  wound,
  situational,
  equipment,
  cyberware;

  /// Human-readable display name for this modifier type.
  String get displayName => switch (this) {
        ModifierType.spell => 'Zauber',
        ModifierType.adeptPower => 'Adeptenkraft',
        ModifierType.wound => 'Wunde',
        ModifierType.situational => 'Situation',
        ModifierType.equipment => 'Ausrüstung',
        ModifierType.cyberware => 'Cyberware',
      };
}

/// A temporary or permanent modifier applied to a stat or attribute.
///
/// Modifiers are identified by [sourceId] — adding a modifier with
/// an existing [sourceId] replaces the previous one. This prevents
/// the same source (e.g. a spell) from stacking with itself.
class StatModifier extends Equatable {
  /// Unique identifier of the source that applied this modifier.
  final String sourceId;

  /// Human-readable name of the source, used for display purposes.
  final String sourceName;

  /// The modifier value — positive for bonuses, negative for penalties.
  final int value;

  /// The category this modifier belongs to.
  final ModifierType type;

  const StatModifier({
    required this.sourceId,
    required this.sourceName,
    required this.value,
    required this.type,
  });

  factory StatModifier.fromJson(Map<String, dynamic> json) {
    return StatModifier(
      sourceId: json['source_id'] as String,
      sourceName: json['source_name'] as String,
      value: json['value'] as int,
      type: ModifierType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ModifierType.situational,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'source_id': sourceId,
        'source_name': sourceName,
        'value': value,
        'type': type.name,
      };

  @override
  List<Object?> get props => [sourceId, sourceName, value, type];

  @override
  String toString() => 'StatModifier($sourceName: $value, type: ${type.name})';
}
