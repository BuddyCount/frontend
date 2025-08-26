import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../models/expense.dart';
import '../models/group.dart';
import '../models/person.dart';
import 'add_expense_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BuddyCount'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddExpenseScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show app info instead of navigating to landing page
              showAboutDialog(
                context: context,
                applicationName: 'BuddyCount',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.account_balance),
                children: const [
                  Text('A shared budget management app for friends and groups.'),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<GroupProvider>(
        builder: (context, groupProvider, child) {
          final currentGroup = groupProvider.currentGroup;
          
          if (currentGroup == null) {
            return const Center(
              child: Text('No group selected'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGroupHeader(currentGroup),
                const SizedBox(height: 24),
                _buildBalancesSection(currentGroup),
                const SizedBox(height: 24),
                _buildExpensesSection(context, currentGroup, groupProvider),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddExpenseScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGroupHeader(Group group) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${group.members.length} members • ${group.expenses.length} expenses',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalancesSection(Group group) {
    final balances = _calculateBalances(group);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balances',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            ...balances.entries.map((entry) {
              final person = group.members.firstWhere((p) => p.id == entry.key);
              final balance = entry.value;
              final isPositive = balance > 0;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      person.name,
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      NumberFormat.currency(symbol: '\$').format(balance.abs()),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesSection(BuildContext context, Group group, GroupProvider groupProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Expenses',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddExpenseScreen(),
                      ),
                    );
                  },
                  child: const Text('Add New'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (group.expenses.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'No expenses yet.\nTap the + button to add your first expense!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              ...group.expenses.reversed.take(5).map((expense) {
                return _buildExpenseTile(expense, group);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseTile(Expense expense, Group group) {
    final payer = group.members.firstWhere((p) => p.id == expense.paidBy);
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.withValues(alpha: 0.1),
        child: Icon(
          Icons.receipt,
          color: Colors.blue.withValues(alpha: 0.8),
        ),
      ),
      title: Text(expense.name),
      subtitle: Text(
        'Paid by ${payer.name} • ${DateFormat('MMM dd').format(expense.date)}',
      ),
      trailing: Text(
        NumberFormat.currency(symbol: '\$').format(expense.amount),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Map<String, double> _calculateBalances(Group group) {
    final balances = <String, double>{};
    
    // Initialize balances
    for (final person in group.members) {
      balances[person.id] = 0.0;
    }
    
    // Calculate balances from expenses
    for (final expense in group.expenses) {
      final payerId = expense.paidBy;
      final amountPerPerson = expense.amount / expense.splitBetween.length;
      
      // Add the full amount to the payer
      balances[payerId] = (balances[payerId] ?? 0) + expense.amount;
      
      // Subtract the split amount from each person who owes
      for (final personId in expense.splitBetween) {
        balances[personId] = (balances[personId] ?? 0) - amountPerPerson;
      }
    }
    
    return balances;
  }
} 