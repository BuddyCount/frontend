import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/widgets/expense_analytics_widget.dart';
import '../../lib/models/group.dart';
import '../../lib/models/person.dart';
import '../../lib/models/expense.dart';

void main() {
  group('ExpenseAnalyticsWidget Tests', () {
    late Group testGroup;
    late Person testPerson1;
    late Person testPerson2;
    late List<Expense> testExpenses;

    setUp(() {
      testPerson1 = Person(id: '1', name: 'John');
      testPerson2 = Person(id: '2', name: 'Jane');
      
      testExpenses = [
        Expense(
          id: '1',
          name: 'Lunch',
          amount: 25.0,
          currency: 'USD',
          date: DateTime.now().subtract(const Duration(days: 1)),
          paidBy: '1',
          splitBetween: ['1', '2'],
          groupId: 'group1',
        ),
        Expense(
          id: '2',
          name: 'Dinner',
          amount: 40.0,
          currency: 'USD',
          date: DateTime.now(),
          paidBy: '2',
          splitBetween: ['1', '2'],
          groupId: 'group1',
        ),
      ];
      
      testGroup = Group(
        id: 'group1',
        name: 'Test Group',
        members: [testPerson1, testPerson2],
        expenses: testExpenses,
      );
    });

    testWidgets('should render analytics widget with group data', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ExpenseAnalyticsWidget(group: testGroup),
            ),
          ),
        ),
      );

      // Check that the widget renders
      expect(find.text('Expense Analytics'), findsOneWidget);
      expect(find.text('Summary'), findsOneWidget);
      expect(find.text('\$65.00'), findsOneWidget); // Total amount
      expect(find.text('\$32.50'), findsOneWidget); // Daily average
    });

    testWidgets('should show filter chips', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ExpenseAnalyticsWidget(group: testGroup),
            ),
          ),
        ),
      );

      // Check that filter chips are present
      expect(find.text('Last 30 days'), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
    });

    testWidgets('should handle empty expenses gracefully', (WidgetTester tester) async {
      final emptyGroup = Group(
        id: 'empty',
        name: 'Empty Group',
        members: [testPerson1],
        expenses: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ExpenseAnalyticsWidget(group: emptyGroup),
            ),
          ),
        ),
      );

      // Should still render the widget
      expect(find.text('Expense Analytics'), findsOneWidget);
      expect(find.text('No expenses in selected period'), findsOneWidget);
    });

    testWidgets('should show filter dialog when filter button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ExpenseAnalyticsWidget(group: testGroup),
            ),
          ),
        ),
      );

      // Tap the filter button
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Check that the filter dialog appears
      expect(find.text('Filter Options'), findsOneWidget);
      expect(find.text('Time Range'), findsOneWidget);
      expect(find.text('Filter by Member'), findsOneWidget);
    });
  });
}
