import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../models/group.dart';
import '../models/expense.dart';
import 'add_expense_screen.dart';
import 'package:intl/intl.dart';
import '../widgets/expense_analytics_widget.dart';

class GroupDetailScreen extends StatelessWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Colors.red.shade400,
            ),
            onPressed: () => _showDeleteConfirmation(context),
            tooltip: 'Delete Group',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
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
          // Get the latest version of the group from the provider
          final currentGroup = groupProvider.groups.firstWhere(
            (g) => g.id == group.id,
            orElse: () => group,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGroupHeader(currentGroup),
                const SizedBox(height: 24),
                _buildBalancesSection(currentGroup),
                const SizedBox(height: 24),
                _buildExpenseAnalyticsSection(currentGroup),
                const SizedBox(height: 24),
                _buildExpensesSection(context, currentGroup, groupProvider),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Set the current group before navigating to AddExpenseScreen
          final groupProvider = Provider.of<GroupProvider>(context, listen: false);
          groupProvider.setCurrentGroup(group);
          
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
            const SizedBox(height: 16),
            Text(
              'Members: ${group.members.map((p) => p.name).join(', ')}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseAnalyticsSection(Group group) {
    return ExpenseAnalyticsWidget(group: group);
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
                  children: [
                    Expanded(
                      child: Text(
                        person.name,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isPositive ? Colors.green.shade100 : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isPositive ? Colors.green.shade300 : Colors.red.shade300,
                        ),
                      ),
                      child: Text(
                        '${isPositive ? '+' : ''}\$${balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesSection(BuildContext context, Group group, GroupProvider groupProvider) {
    if (group.expenses.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.receipt_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No expenses yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your first expense to get started!',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Expenses',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                Text(
                  'Total: \$${group.expenses.fold(0.0, (sum, expense) => sum + expense.amount).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...group.expenses.map((expense) => _buildExpenseTile(context, expense, group, groupProvider)),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseTile(BuildContext context, Expense expense, Group group, GroupProvider groupProvider) {
    final payer = group.members.firstWhere((p) => p.id == expense.paidBy);
    final splitAmount = expense.amount / expense.splitBetween.length;
    
    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Expense'),
            content: Text(
              'Are you sure you want to delete "${expense.name}"?\n\n'
              'This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deleting expense...'),
            duration: Duration(seconds: 1),
          ),
        );
        
        // Delete the expense
        await groupProvider.removeExpense(expense.id);
        
        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Expense "${expense.name}" deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(
            Icons.receipt,
            color: Colors.blue.shade700,
          ),
        ),
        title: Text(
          expense.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paid by ${payer.name} • ${DateFormat('MMM dd, yyyy').format(expense.date)}',
              style: TextStyle(fontSize: 14),
            ),
            Text(
              'Split between ${expense.splitBetween.length} people',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${expense.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              '\$${splitAmount.toStringAsFixed(2)} each',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, double> _calculateBalances(Group group) {
    final balances = <String, double>{};
    
    // Initialize all balances to 0
    for (final person in group.members) {
      balances[person.id] = 0.0;
    }
    
    // Calculate balances based on expenses
    for (final expense in group.expenses) {
      final payer = group.members.firstWhere((p) => p.id == expense.paidBy);
      final splitAmount = expense.amount / expense.splitBetween.length;
      
      // Payer gets the full amount
      balances[payer.id] = (balances[payer.id] ?? 0.0) + expense.amount;
      
      // Each person in split pays their share
      for (final personId in expense.splitBetween) {
        balances[personId] = (balances[personId] ?? 0.0) - splitAmount;
      }
    }
    
    return balances;
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text(
          'Are you sure you want to delete "${group.name}"?\n\n'
          'This will permanently remove the group and all its expenses. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              // Get the GroupProvider
              final groupProvider = Provider.of<GroupProvider>(context, listen: false);
              
              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Deleting group...'),
                  duration: Duration(seconds: 1),
                ),
              );
              
              // Delete the group
              await groupProvider.removeGroup(group.id);
              
              // Navigate back to groups overview
              if (context.mounted) {
                Navigator.of(context).pop();
                
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Group "${group.name}" deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

