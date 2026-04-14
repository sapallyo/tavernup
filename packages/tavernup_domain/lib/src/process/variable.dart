import 'package:equatable/equatable.dart';

enum VariableType { string, integer, double, boolean, json }

class Variable extends Equatable {
  final VariableType type;
  final dynamic value;

  const Variable._({required this.type, required this.value});

  factory Variable.string(String value) =>
      Variable._(type: VariableType.string, value: value);

  factory Variable.integer(int value) =>
      Variable._(type: VariableType.integer, value: value);

  factory Variable.double(double value) =>
      Variable._(type: VariableType.double, value: value);

  factory Variable.boolean(bool value) =>
      Variable._(type: VariableType.boolean, value: value);

  factory Variable.json(Map<String, dynamic> value) =>
      Variable._(type: VariableType.json, value: value);

  factory Variable.fromTypeAndValue(VariableType type, dynamic value) {
    return switch (type) {
      VariableType.string => Variable.string(value as String),
      VariableType.integer => Variable.integer(value as int),
      VariableType.double => Variable.double((value as num).toDouble()),
      VariableType.boolean => Variable.boolean(value as bool),
      VariableType.json => Variable.json(value as Map<String, dynamic>),
    };
  }

  @override
  List<Object?> get props => [type, value];

  @override
  String toString() => 'Variable($type: $value)';
}
