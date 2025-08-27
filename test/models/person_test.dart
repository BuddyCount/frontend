import 'package:flutter_test/flutter_test.dart';
import 'package:buddycount_frontend/models/person.dart';

void main() {
  group('Person Model Tests', () {
    late Person testPerson;

    setUp(() {
      testPerson = Person(
        id: '1',
        name: 'Alice',
        balance: 25.50,
      );
    });

    test('should create a person with all required fields', () {
      expect(testPerson.id, '1');
      expect(testPerson.name, 'Alice');
      expect(testPerson.balance, 25.50);
    });

    test('should create a person from JSON', () {
      final json = {
        'id': '1',
        'name': 'Alice',
        'balance': 25.50,
      };

      final person = Person.fromJson(json);
      
      expect(person.id, '1');
      expect(person.name, 'Alice');
      expect(person.balance, 25.50);
    });

    test('should convert person to JSON', () {
      final json = testPerson.toJson();
      
      expect(json['id'], '1');
      expect(json['name'], 'Alice');
      expect(json['balance'], 25.50);
    });

    test('should create a copy of person with modifications', () {
      final modifiedPerson = testPerson.copyWith(
        name: 'Bob',
        balance: 0.0,
      );
      
      expect(modifiedPerson.id, '1');
      expect(modifiedPerson.name, 'Bob');
      expect(modifiedPerson.balance, 0.0);
    });

    test('should handle zero balance', () {
      final zeroBalancePerson = Person(
        id: '2',
        name: 'Bob',
        balance: 0.0,
      );
      
      expect(zeroBalancePerson.balance, 0.0);
    });

    test('should handle negative balance', () {
      final negativeBalancePerson = Person(
        id: '3',
        name: 'Charlie',
        balance: -15.75,
      );
      
      expect(negativeBalancePerson.balance, -15.75);
    });

    test('should handle decimal balance precision', () {
      final preciseBalancePerson = Person(
        id: '4',
        name: 'David',
        balance: 12.345,
      );
      
      expect(preciseBalancePerson.balance, 12.345);
    });
  });
}
