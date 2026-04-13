import 'variable.dart';

abstract interface class IProcessTask {
  String get id;
  String get name;
  String get processInstanceId;
  Map<String, Variable> get variables;
}
