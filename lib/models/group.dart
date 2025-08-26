import 'expense.dart';
import 'person.dart';

class Group {
  final String id;
  final String name;
  final List<Person> members;
  final List<Expense> expenses;
  final String currency;

  Group({
    required this.id,
    required this.name,
    required this.members,
    required this.currency,
    List<Expense>? expenses,
  }) : expenses = expenses ?? [];

  double get totalExpenses {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  void addExpense(Expense expense) {
    expenses.add(expense);
    _updateBalances();
  }

  void removeExpense(String expenseId) {
    expenses.removeWhere((expense) => expense.id == expenseId);
    _updateBalances();
  }

  void _updateBalances() {
    // Reset all balances
    for (var person in members) {
      person.balance = 0.0;
    }

    // Calculate balances based on expenses
    for (var expense in expenses) {
      final payer = members.firstWhere((p) => p.id == expense.paidBy);
      final splitAmount = expense.amount / expense.splitBetween.length;
      
      payer.balance += expense.amount;
      
      for (var personId in expense.splitBetween) {
        if (personId != expense.paidBy) {
          final person = members.firstWhere((p) => p.id == personId);
          person.balance -= splitAmount;
        } else {
          payer.balance -= splitAmount;
        }
      }
    }
  }

  Group copyWith({
    String? id,
    String? name,
    List<Person>? members,
    List<Expense>? expenses,
    String? currency,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      members: members ?? this.members,
      expenses: expenses ?? this.expenses,
      currency: currency ?? this.currency,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'members': members.map((m) => m.toJson()).toList(),
      'expenses': expenses.map((e) => e.toJson()).toList(),
      'currency': currency,
    };
  }

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
      members: (json['members'] as List)
          .map((m) => Person.fromJson(m))
          .toList(),
      expenses: (json['expenses'] as List)
          .map((e) => Expense.fromJson(e))
          .toList(),
      currency: json['currency'],
    );
  }
} 