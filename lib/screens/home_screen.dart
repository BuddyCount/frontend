import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../models/expense.dart';
import '../models/group.dart';

import 'add_expense_screen.dart';
import '../widgets/group_dialog.dart';
import '../services/sync_service.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final SyncService _syncService;

  @override
  void initState() {
    super.initState();
    _syncService = SyncService();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _syncService.initialize(context);
  }

  @override
  void dispose() {
    _syncService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BuddyCount'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Connectivity indicator
          IconButton(
            icon: Icon(
              _syncService.isOnline ? Icons.wifi : Icons.wifi_off,
              color: _syncService.isOnline ? Colors.green : Colors.orange,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _syncService.isOnline 
                      ? 'Online - Changes will sync automatically'
                      : 'Offline - Changes saved locally, will sync when online'
                  ),
                  backgroundColor: _syncService.isOnline ? Colors.green : Colors.orange,
                ),
              );
            },
            tooltip: _syncService.isOnline ? 'Online' : 'Offline',
          ),
          // Manual sync button
          if (_syncService.isOnline)
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () async {
                await _syncService.manualSync(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Manual sync completed!'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              tooltip: 'Manual Sync',
            ),
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: () => _showGroupDialog(context),
            tooltip: 'Create or Join Group',
          ),
          Consumer<GroupProvider>(
            builder: (context, groupProvider, child) {
              // Only show Add Expense button if there are groups
              if (groupProvider.groups.isEmpty) return const SizedBox.shrink();
              
              return IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddExpenseScreen(),
                    ),
                  );
                },
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
            return _buildEmptyState(context);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGroupHeader(currentGroup),
                const SizedBox(height: 24),
                _buildGroupsOverview(context, groupProvider),
                const SizedBox(height: 24),
                _buildBalancesSection(currentGroup),
                const SizedBox(height: 24),
                _buildExpensesSection(context, currentGroup, groupProvider),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Consumer<GroupProvider>(
        builder: (context, groupProvider, child) {
          // Only show FAB if there are groups
          if (groupProvider.groups.isEmpty) return const SizedBox.shrink();
          
          return FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddExpenseScreen(),
                ),
              );
            },
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to BuddyCount!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You don\'t have any groups yet.\nCreate your first group to start managing shared expenses!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Once you have a group, you can add expenses and track balances.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showGroupDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Group'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showGroupDialog(context),
                  icon: const Icon(Icons.link),
                  label: const Text('Join Group'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '💡 Tip: Groups are perfect for trips, roommates, events, and more!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'After creating a group, you\'ll be able to:\n• Add expenses and track spending\n• Split costs between members\n• View balances and settlements\n• Manage multiple groups',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupsOverview(BuildContext context, GroupProvider groupProvider) {
                    if (groupProvider.groups.length <= 1) {
                  return const SizedBox.shrink();
                }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Groups',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            ...groupProvider.groups.map((group) {
              final isCurrentGroup = group.id == groupProvider.currentGroup?.id;
              return ListTile(
                leading: Icon(
                  isCurrentGroup ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isCurrentGroup ? Theme.of(context).primaryColor : Colors.grey,
                ),
                title: Text(
                  group.name,
                  style: TextStyle(
                    fontWeight: isCurrentGroup ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text('${group.members.length} members • ${group.expenses.length} expenses'),
                trailing: isCurrentGroup 
                  ? const Chip(label: Text('Current'), backgroundColor: Colors.blue)
                  : TextButton(
                      onPressed: () => groupProvider.setCurrentGroup(group),
                      child: const Text('Switch to'),
                    ),
                onTap: () => groupProvider.setCurrentGroup(group),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _showGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const GroupDialog(),
    ).then((result) {
      if (result != null) {
        // Handle the result - you can update the group provider here
        // For now, just show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Group operation completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  Widget _buildGroupHeader(Group group) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    group.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Group selector dropdown
                Consumer<GroupProvider>(
                  builder: (context, provider, child) {
                    if (provider.groups.length <= 1) {
                    return const SizedBox.shrink();
                  }
                    
                    return DropdownButton<Group>(
                      value: group,
                      items: provider.groups.map((g) => 
                        DropdownMenuItem(
                          value: g,
                          child: Text(g.name, style: const TextStyle(fontSize: 16)),
                        )
                      ).toList(),
                      onChanged: (Group? newGroup) {
                        if (newGroup != null) {
                          provider.setCurrentGroup(newGroup);
                        }
                      },
                      underline: Container(),
                      icon: const Icon(Icons.arrow_drop_down),
                    );
                  },
                ),
              ],
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