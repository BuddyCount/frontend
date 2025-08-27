import 'package:flutter_test/flutter_test.dart';
import 'package:buddycount_frontend/models/expense.dart';

void main() {
  group('Expense Model Tests', () {
    late Expense testExpense;

    setUp(() {
      testExpense = Expense(
        id: 'exp1',
        name: 'Lunch',
        amount: 25.50,
        currency: 'USD',
        paidBy: '1',
        splitBetween: ['1', '2', '3'],
        date: DateTime(2024, 1, 1, 12, 0),
        groupId: 'group1',
      );
    });

    test('should create an expense with all required fields', () {
      expect(testExpense.id, 'exp1');
      expect(testExpense.name, 'Lunch');
      expect(testExpense.amount, 25.50);
      expect(testExpense.currency, 'USD');
      expect(testExpense.paidBy, '1');
      expect(testExpense.splitBetween, hasLength(3));
      expect(testExpense.groupId, 'group1');
    });

    test('should create an expense from JSON', () {
      final json = {
        'id': 'exp1',
        'name': 'Lunch',
        'amount': 25.50,
        'currency': 'USD',
        'paidBy': '1',
        'splitBetween': ['1', '2', '3'],
        'date': '2024-01-01T12:00:00.000Z',
        'groupId': 'group1',
      };

      final expense = Expense.fromJson(json);
      
      expect(expense.id, 'exp1');
      expect(expense.name, 'Lunch');
      expect(expense.amount, 25.50);
      expect(expense.currency, 'USD');
      expect(expense.paidBy, '1');
      expect(expense.splitBetween, hasLength(3));
      expect(expense.groupId, 'group1');
    });

    test('should convert expense to JSON', () {
      final json = testExpense.toJson();
      
      expect(json['id'], 'exp1');
      expect(json['name'], 'Lunch');
      expect(json['amount'], 25.50);
      expect(json['currency'], 'USD');
      expect(json['paidBy'], '1');
      expect(json['splitBetween'], hasLength(3));
      expect(json['groupId'], 'group1');
    });

    test('should create a copy of expense with modifications', () {
      final modifiedExpense = testExpense.copyWith(
        name: 'Dinner',
        amount: 50.0,
        currency: 'EUR',
      );
      
      expect(modifiedExpense.id, 'exp1');
      expect(modifiedExpense.name, 'Dinner');
      expect(modifiedExpense.amount, 50.0);
      expect(modifiedExpense.currency, 'EUR');
      expect(modifiedExpense.paidBy, '1');
      expect(modifiedExpense.splitBetween, hasLength(3));
    });

    test('should handle different currencies', () {
      final eurExpense = Expense(
        id: 'exp2',
        name: 'Coffee',
        amount: 3.50,
        currency: 'EUR',
        paidBy: '2',
        splitBetween: ['2'],
        date: DateTime(2024, 1, 1),
        groupId: 'group1',
      );
      
      expect(eurExpense.currency, 'EUR');
      expect(eurExpense.amount, 3.50);
    });

    test('should handle single person split', () {
      final singleSplitExpense = Expense(
        id: 'exp3',
        name: 'Personal Item',
        amount: 15.0,
        currency: 'USD',
        paidBy: '1',
        splitBetween: ['1'],
        date: DateTime(2024, 1, 1),
        groupId: 'group1',
      );
      
      expect(singleSplitExpense.splitBetween, hasLength(1));
      expect(singleSplitExpense.splitBetween.first, '1');
    });

    test('should handle zero amount', () {
      final zeroExpense = Expense(
        id: 'exp4',
        name: 'Free Event',
        amount: 0.0,
        currency: 'USD',
        paidBy: '1',
        splitBetween: ['1', '2'],
        date: DateTime(2024, 1, 1),
        groupId: 'group1',
      );
      
      expect(zeroExpense.amount, 0.0);
    });

    test('should handle missing groupId in fromJson', () {
      final json = {
        'id': 'exp1',
        'name': 'Lunch',
        'amount': 25.50,
        'currency': 'USD',
        'paidBy': '1',
        'splitBetween': ['1', '2'],
        'date': '2024-01-01T12:00:00.000Z',
        // groupId is missing
      };

      final expense = Expense.fromJson(json);
      
      expect(expense.groupId, ''); // Should default to empty string
    });
  });
}
