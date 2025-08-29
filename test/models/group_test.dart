import 'package:flutter_test/flutter_test.dart';
import 'package:buddycount_frontend/models/group.dart';
import 'package:buddycount_frontend/models/person.dart';
import 'package:buddycount_frontend/models/expense.dart';

void main() {
  group('Group Model Tests', () {
    late Person person1;
    late Person person2;
    late Expense expense1;
    late Group testGroup;

    setUp(() {
      person1 = Person(id: '1', name: 'Alice');
      person2 = Person(id: '2', name: 'Bob');
      expense1 = Expense(
        id: 'exp1',
        name: 'Lunch',
        amount: 25.0,
        currency: 'USD',
        paidBy: '1',
        splitBetween: ['1', '2'],
        date: DateTime(2024, 1, 1),
        groupId: 'group1',
      );
      
      testGroup = Group(
        id: 'group1',
        name: 'Test Group',
        description: 'Test Description',
        currency: 'USD',
        members: [person1, person2],
        expenses: [expense1],
      );
    });

    test('should create a group with all required fields', () {
      expect(testGroup.id, 'group1');
      expect(testGroup.name, 'Test Group');
      expect(testGroup.members, hasLength(2));
      expect(testGroup.expenses, hasLength(1));
    });

    test('should create a group from JSON', () {
      final json = {
        'id': 'group1',
        'name': 'Test Group',
        'members': [
          {'id': '1', 'name': 'Alice', 'balance': 0.0},
          {'id': '2', 'name': 'Bob', 'balance': 0.0},
        ],
        'expenses': [
          {
            'id': 'exp1',
            'name': 'Lunch',
            'amount': 25.0,
            'currency': 'USD',
            'paidBy': '1',
            'splitBetween': ['1', '2'],
            'date': '2024-01-01T00:00:00.000Z',
            'groupId': 'group1',
          },
        ],
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-01T00:00:00.000Z',
      };

      final group = Group.fromJson(json);
      
      expect(group.id, 'group1');
      expect(group.name, 'Test Group');
      expect(group.members, hasLength(2));
      expect(group.expenses, hasLength(1));
    });

    test('should convert group to JSON', () {
      final json = testGroup.toJson();
      
      expect(json['id'], 'group1');
      expect(json['name'], 'Test Group');
      expect(json['members'], hasLength(2));
      expect(json['expenses'], hasLength(1));
    });

    test('should create a copy of group with modifications', () {
      final modifiedGroup = testGroup.copyWith(
        name: 'Modified Group',
        members: [person1],
      );
      
      expect(modifiedGroup.id, 'group1');
      expect(modifiedGroup.name, 'Modified Group');
      expect(modifiedGroup.members, hasLength(1));
      expect(modifiedGroup.expenses, hasLength(1));
    });

    test('should handle empty members and expenses lists', () {
      final emptyGroup = Group(
        id: 'empty',
        name: 'Empty Group',
        description: 'Empty Description',
        currency: 'USD',
        members: [],
        expenses: [],
      );
      
      expect(emptyGroup.members, isEmpty);
      expect(emptyGroup.expenses, isEmpty);
    });

    test('should handle null expenses in fromJson gracefully', () {
      final json = {
        'id': 'group1',
        'name': 'Test Group',
        'members': [
          {'id': '1', 'name': 'Alice', 'balance': 0.0},
        ],
        'expenses': null,
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-01T00:00:00.000Z',
      };

      final group = Group.fromJson(json);
      
      expect(group.members, hasLength(1));
      expect(group.expenses, isEmpty);
    });
  });
}
