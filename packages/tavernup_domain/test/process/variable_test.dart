import 'package:tavernup_domain/tavernup_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Variable factories', () {
    test('string', () {
      final v = Variable.string('hello');
      expect(v.type, VariableType.string);
      expect(v.value, 'hello');
    });

    test('integer', () {
      final v = Variable.integer(42);
      expect(v.type, VariableType.integer);
      expect(v.value, 42);
    });

    test('double', () {
      final v = Variable.double(3.14);
      expect(v.type, VariableType.double);
      expect(v.value, 3.14);
    });

    test('boolean', () {
      final v = Variable.boolean(true);
      expect(v.type, VariableType.boolean);
      expect(v.value, true);
    });

    test('json', () {
      final v = Variable.json({'key': 'value'});
      expect(v.type, VariableType.json);
      expect(v.value, {'key': 'value'});
    });
  });

  group('fromTypeAndValue', () {
    test('roundtrip string', () {
      final original = Variable.string('hello');
      final restored = Variable.fromTypeAndValue(original.type, original.value);
      expect(restored, original);
    });

    test('roundtrip integer', () {
      final original = Variable.integer(42);
      final restored = Variable.fromTypeAndValue(original.type, original.value);
      expect(restored, original);
    });

    test('roundtrip double', () {
      final original = Variable.double(3.14);
      final restored = Variable.fromTypeAndValue(original.type, original.value);
      expect(restored, original);
    });

    test('roundtrip boolean', () {
      final original = Variable.boolean(false);
      final restored = Variable.fromTypeAndValue(original.type, original.value);
      expect(restored, original);
    });

    test('roundtrip json', () {
      final original = Variable.json({'key': 'value'});
      final restored = Variable.fromTypeAndValue(original.type, original.value);
      expect(restored, original);
    });
  });

  group('equality', () {
    test('same type and value are equal', () {
      expect(Variable.string('a'), Variable.string('a'));
    });

    test('different values are not equal', () {
      expect(Variable.string('a'), isNot(Variable.string('b')));
    });

    test('different types are not equal', () {
      expect(Variable.integer(1), isNot(Variable.boolean(true)));
    });
  });
}
