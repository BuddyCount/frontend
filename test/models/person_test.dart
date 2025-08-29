import 'package:flutter_test/flutter_test.dart';
import 'package:buddycount_frontend/models/person.dart';

void main() {
  group('Person Model Tests', () {
    late Person testPerson;

    setUp(() {
      testPerson = Person(
        id: '1',
        name: 'Alice',
      );
    });

    test('should create a person with all required fields', () {
      expect(testPerson.id, '1');
      expect(testPerson.name, 'Alice');
    });

    test('should create a person from JSON', () {
      final json = {
        'id': '1',
        'name': 'Alice',
      };

      final person = Person.fromJson(json);
      
      expect(person.id, '1');
      expect(person.name, 'Alice');
    });

    test('should convert person to JSON', () {
      final json = testPerson.toJson();
      
      expect(json['id'], '1');
      expect(json['name'], 'Alice');
    });

    test('should create a copy of person with modifications', () {
      final modifiedPerson = testPerson.copyWith(
        name: 'Bob',
      );
      
      expect(modifiedPerson.id, '1');
      expect(modifiedPerson.name, 'Bob');
    });

    test('should handle person creation', () {
      final newPerson = Person(
        id: '2',
        name: 'Bob',
      );
      
      expect(newPerson.id, '2');
      expect(newPerson.name, 'Bob');
    });

    test('should handle person with special characters', () {
      final specialPerson = Person(
        id: '3',
        name: 'Charlie-O\'Connor',
      );
      
      expect(specialPerson.id, '3');
      expect(specialPerson.name, 'Charlie-O\'Connor');
    });

    test('should handle person with numbers in name', () {
      final numberPerson = Person(
        id: '4',
        name: 'David123',
      );
      
      expect(numberPerson.id, '4');
      expect(numberPerson.name, 'David123');
    });
  });
}
