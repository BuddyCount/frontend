import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/group_provider.dart';
import '../models/group.dart';
import '../models/expense.dart';
import '../models/person.dart';
import '../services/sync_service.dart';
import 'add_expense_screen.dart';
import 'expense_detail_screen.dart';
import 'package:intl/intl.dart';
import '../widgets/expense_analytics_widget.dart';

class Settlement {
  final String fromId;
  final String toId;
  final double amount;
  
  const Settlement({
    required this.fromId,
    required this.toId,
    required this.amount,
  });
}

class GroupDetailScreen extends StatefulWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  Person? _selectedMember;
  String _selectedTimeRange = 'all'; // 7d, 30d, 90d, 1y, all

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(
              Icons.share,
              color: Colors.blue.shade400,
            ),
            onPressed: () => _showShareDialog(context),
            tooltip: 'Share Group',
          ),
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
            (g) => g.id == widget.group.id,
            orElse: () => widget.group,
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
                _buildExpensesSection(context, currentGroup, groupProvider),
                const SizedBox(height: 24),
                _buildExpenseAnalyticsSection(currentGroup),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Set the current group before navigating to AddExpenseScreen
          final groupProvider = Provider.of<GroupProvider>(context, listen: false);
          groupProvider.setCurrentGroup(widget.group);
          
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
              final person = group.members.firstWhere(
                (p) => p.id == entry.key,
                orElse: () => group.members.first, // Fallback to first member if not found
              );
              final balance = entry.value;
              final isPositive = balance > 0;
              final isZero = balance == 0;
              
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
                        color: isZero 
                          ? Colors.grey.shade100 
                          : (isPositive ? Colors.green.shade100 : Colors.red.shade100),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isZero 
                            ? Colors.grey.shade300 
                            : (isPositive ? Colors.green.shade300 : Colors.red.shade300),
                        ),
                      ),
                      child: Text(
                        isZero 
                          ? '\$${balance.toStringAsFixed(2)}'
                          : '\$${isPositive ? '+' : '-'}${balance.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          color: isZero 
                            ? Colors.grey.shade700 
                            : (isPositive ? Colors.green.shade700 : Colors.red.shade700),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Debt Settlements',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            _buildDebtSettlements(balances, group),
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
                  'Total: \$${_getFilteredExpenses(group).fold(0.0, (sum, expense) => sum + expense.amount).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildExpenseFilters(context, group),
            const SizedBox(height: 16),
            ..._getFilteredExpenses(group).map((expense) => _buildExpenseTile(context, expense, group, groupProvider)),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseTile(BuildContext context, Expense expense, Group group, GroupProvider groupProvider) {
    final payer = group.members.firstWhere(
      (p) => p.id == expense.paidBy || p.name == expense.paidBy,
      orElse: () => group.members.first, // Fallback to first member if not found
    );
    
    // Calculate split amount based on custom shares or equal splitting
    double splitAmount;
    if (expense.customShares != null && expense.customShares!.isNotEmpty) {
      // Use custom shares for proportional splitting
      final totalShares = expense.customShares!.values.reduce((a, b) => a + b);
      // For display purposes, show the average share amount
      splitAmount = expense.amount / totalShares;
    } else {
      // Equal splitting
      splitAmount = expense.amount / expense.splitBetween.length;
    }
    
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
        
        // Delete the expense using sync service for proper online/offline handling
        try {
          final syncService = SyncService();
          await syncService.deleteExpenseOffline(expense.id, context, groupProvider);
          
          // Show success message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Expense "${expense.name}" deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          // Show error message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error deleting expense: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExpenseDetailScreen(expense: expense),
            ),
          );
        },
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
              expense.customPaidBy != null && expense.customPaidBy!.isNotEmpty
                ? 'Paid by multiple people • ${DateFormat('MMM dd, yyyy').format(expense.date)}'
                : 'Paid by ${payer.name} • ${DateFormat('MMM dd, yyyy').format(expense.date)}',
              style: TextStyle(fontSize: 14),
            ),
            Text(
              'Split between ${expense.splitBetween.length} people',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            // Show multiple payers details if applicable
            if (expense.customPaidBy != null && expense.customPaidBy!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                expense.customPaidBy!.entries
                    .where((entry) => entry.value > 0)
                    .map((entry) {
                  final person = group.members.firstWhere(
                    (p) => p.id == entry.key,
                    orElse: () => group.members.first, // Fallback to first member if not found
                  );
                  return '${person.name}: \$${entry.value.toStringAsFixed(2)}';
                }).join(', '),
                style: TextStyle(fontSize: 11, color: Colors.blue.shade600),
              ),
            ],
            // Show images if available
            if (expense.images != null && expense.images!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.photo, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${expense.images!.length} image${expense.images!.length > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${expense.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: expense.customPaidBy != null && expense.customPaidBy!.isNotEmpty ? 14 : 16,

                  ),
                ),
                Text(
                  expense.customShares != null && expense.customShares!.isNotEmpty
                    ? 'Shares: ${expense.customShares!.values.map((s) => s.toStringAsFixed(1)).join(', ')}'
                    : '\$${splitAmount.toStringAsFixed(2)} each',
                  style: TextStyle(

                    fontSize: expense.customPaidBy != null && expense.customPaidBy!.isNotEmpty ? 10 : 12,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                // Show payment info for multiple payers
                if (expense.customPaidBy != null && expense.customPaidBy!.isNotEmpty) ...[
                  Text(
                    'Multi-pay',
                    style: TextStyle(
                      fontSize: 8,

                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                // Show payment info for multiple payers
                if (expense.customPaidBy != null && expense.customPaidBy!.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    'Multi-pay',
                    style: TextStyle(
                      fontSize: 9,

                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddExpenseScreen(expenseToEdit: expense),
                  ),
                );
              },
              icon: Icon(
                Icons.edit,
                color: Colors.blue.shade600,
                size: 20,
              ),
              tooltip: 'Edit expense',
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
      final payer = group.members.firstWhere(
        (p) => p.id == expense.paidBy || p.name == expense.paidBy,
        orElse: () => group.members.first, // Fallback to first member if not found
      );
      
      // Handle multiple payers or single payer
      if (expense.customPaidBy != null && expense.customPaidBy!.isNotEmpty) {
        // Multiple payers with custom amounts
        for (final entry in expense.customPaidBy!.entries) {
          final payerId = entry.key;
          final paidAmount = entry.value;
          balances[payerId] = (balances[payerId] ?? 0.0) + paidAmount;
        }
      } else {
        // Single payer gets the full amount
        balances[payer.id] = (balances[payer.id] ?? 0.0) + expense.amount;
      }
      
      // Calculate how much each person owes based on custom shares or equal splitting
      if (expense.customShares != null && expense.customShares!.isNotEmpty) {
        // Use custom shares for proportional splitting
        final totalShares = expense.customShares!.values.reduce((a, b) => a + b);
        
        for (final personId in expense.splitBetween) {
          final personShares = expense.customShares![personId] ?? 1.0;
          final personAmount = (personShares / totalShares) * expense.amount;
          balances[personId] = (balances[personId] ?? 0.0) - personAmount;
        }
      } else {
        // Equal splitting (original behavior)
        final splitAmount = expense.amount / expense.splitBetween.length;
        
        for (final personId in expense.splitBetween) {
          balances[personId] = (balances[personId] ?? 0.0) - splitAmount;
        }
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
          'Are you sure you want to delete "${widget.group.name}"?\n\n'
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
              // Get provider reference before closing dialog
              final groupProvider = Provider.of<GroupProvider>(context, listen: false);
              
              Navigator.of(context).pop();
              
              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Deleting group...'),
                  duration: Duration(seconds: 1),
                ),
              );
              
              // Delete group directly from provider and storage
              try {
                // Remove from provider immediately
                groupProvider.removeGroup(widget.group.id);
                
                // Navigate back to groups overview
                if (context.mounted) {
                  Navigator.of(context).pop();
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Group "${widget.group.name}" deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                
                // Try to delete from API in background (don't wait for it)
                final syncService = SyncService();
                syncService.deleteGroupOffline(widget.group.id, context, groupProvider).catchError((e) {
                  print('Background API deletion failed: $e');
                  // Don't show error to user since local deletion succeeded
                });
                
              } catch (e) {
                print('Error deleting group: $e');
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting group: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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

  void _showShareDialog(BuildContext context) {
    final shareLink = widget.group.linkToken != null 
        ? 'https://buddycount.app/join/${widget.group.linkToken}'
        : 'No share link available';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.share,
              color: Colors.blue.shade400,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('Share Group'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share "${widget.group.name}" with others:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      shareLink,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.copy,
                      color: Colors.blue.shade400,
                      size: 20,
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: shareLink));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link copied to clipboard!'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'Copy Link',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Anyone with this link can join your group and see all expenses.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseFilters(BuildContext context, Group group) {
    return Row(
      children: [
        // Member filter
        Expanded(
          child: DropdownButtonFormField<Person?>(
            initialValue: _selectedMember,
            decoration: const InputDecoration(
              labelText: 'Filter by Member',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: [
              const DropdownMenuItem<Person?>(
                value: null,
                child: Text('All Members'),
              ),
              ...group.members.map((member) => DropdownMenuItem<Person?>(
                value: member,
                child: Text(member.name),
              )),
            ],
            onChanged: (Person? value) {
              setState(() {
                _selectedMember = value;
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        // Time range filter
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _selectedTimeRange,
            decoration: const InputDecoration(
              labelText: 'Time Range',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Time')),
              DropdownMenuItem(value: '7d', child: Text('Last 7 days')),
              DropdownMenuItem(value: '30d', child: Text('Last 30 days')),
              DropdownMenuItem(value: '90d', child: Text('Last 90 days')),
              DropdownMenuItem(value: '1y', child: Text('Last year')),
            ],
            onChanged: (String? value) {
              setState(() {
                _selectedTimeRange = value ?? 'all';
              });
            },
          ),
        ),
      ],
    );
  }

  List<Expense> _getFilteredExpenses(Group group) {
    List<Expense> filteredExpenses = List.from(group.expenses);
    
    // Filter by member if selected
    if (_selectedMember != null) {
      filteredExpenses = filteredExpenses.where((expense) => 
        expense.paidBy == _selectedMember!.id || 
        expense.splitBetween.contains(_selectedMember!.id)
      ).toList();
    }
    
    // Filter by time range
    if (_selectedTimeRange != 'all') {
      final now = DateTime.now();
      final cutoffDate = _getCutoffDate(now);
      
      if (cutoffDate != null) {
        filteredExpenses = filteredExpenses.where((expense) => 
          expense.date.isAfter(cutoffDate)
        ).toList();
      }
    }
    
    // Sort by date (newest first)
    filteredExpenses.sort((a, b) => b.date.compareTo(a.date));
    
    return filteredExpenses;
  }

  DateTime? _getCutoffDate(DateTime now) {
    switch (_selectedTimeRange) {
      case '7d':
        return now.subtract(const Duration(days: 7));
      case '30d':
        return now.subtract(const Duration(days: 30));
      case '90d':
        return now.subtract(const Duration(days: 90));
      case '1y':
        return DateTime(now.year - 1, now.month, now.day);
      default:
        return null;
    }
  }

  Widget _buildDebtSettlements(Map<String, double> balances, Group group) {
    final settlements = _calculateOptimalSettlements(balances, group);
    
    if (settlements.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'All balances are settled! 🎉',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Column(
      children: settlements.map((settlement) {
        final fromPerson = group.members.firstWhere(
          (p) => p.id == settlement.fromId,
          orElse: () => group.members.first, // Fallback to first member if not found
        );
        final toPerson = group.members.firstWhere(
          (p) => p.id == settlement.toId,
          orElse: () => group.members.first, // Fallback to first member if not found
        );
        
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              // From person (owes money)
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.red.shade100,
                      child: Text(
                        fromPerson.name[0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fromPerson.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow and amount
              Column(
                children: [
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                  Text(
                    '\$${settlement.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              // To person (receives money)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        toPerson.name,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.green.shade100,
                      child: Text(
                        toPerson.name[0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<Settlement> _calculateOptimalSettlements(Map<String, double> balances, Group group) {
    final List<Settlement> settlements = [];
    
    // Separate positive and negative balances
    final creditors = <String, double>{};
    final debtors = <String, double>{};
    
    for (final entry in balances.entries) {
      if (entry.value > 0) {
        creditors[entry.key] = entry.value;
      } else if (entry.value < 0) {
        debtors[entry.key] = entry.value.abs();
      }
    }
    
    // Sort by amount (largest first)
    final sortedCreditors = creditors.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedDebtors = debtors.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Calculate optimal settlements
    int creditorIndex = 0;
    int debtorIndex = 0;
    
    while (creditorIndex < sortedCreditors.length && debtorIndex < sortedDebtors.length) {
      final creditor = sortedCreditors[creditorIndex];
      final debtor = sortedDebtors[debtorIndex];
      
      final amount = creditor.value < debtor.value ? creditor.value : debtor.value;
      
      settlements.add(Settlement(
        fromId: debtor.key,
        toId: creditor.key,
        amount: amount,
      ));
      
      // Update remaining amounts
      if (creditor.value <= debtor.value) {
        creditorIndex++;
        sortedDebtors[debtorIndex] = MapEntry(debtor.key, debtor.value - creditor.value);
        if (sortedDebtors[debtorIndex].value == 0) {
          debtorIndex++;
        }
      } else {
        debtorIndex++;
        sortedCreditors[creditorIndex] = MapEntry(creditor.key, creditor.value - debtor.value);
        if (sortedCreditors[creditorIndex].value == 0) {
          creditorIndex++;
        }
      }
    }
    
    return settlements;
  }
}

