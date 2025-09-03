import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../widgets/group_dialog.dart';
import '../models/group.dart';
import '../services/sync_service.dart';
import 'group_detail_screen.dart';

class GroupsOverviewScreen extends StatelessWidget {
  const GroupsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Groups'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final groupProvider = Provider.of<GroupProvider>(context, listen: false);
              groupProvider.refreshFromStorage();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing data from storage...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: () => _showGroupDialog(context, true),
            tooltip: 'Create or Join Group',
          ),
        ],
      ),
      body: Consumer<GroupProvider>(
        builder: (context, groupProvider, child) {
          // Wait for initialization to complete
          if (!groupProvider.isInitialized) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (groupProvider.groups.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: groupProvider.groups.length,
            itemBuilder: (context, index) {
              final group = groupProvider.groups[index];
              return _buildGroupCard(context, group, groupProvider);
            },
          );
        },
      ),
      floatingActionButton: Consumer<GroupProvider>(
        builder: (context, groupProvider, child) {
          if (groupProvider.groups.isNotEmpty) {
            return FloatingActionButton(
              onPressed: () => _showGroupDialog(context, true),
              child: const Icon(Icons.add),
            );
          }
          return const SizedBox.shrink();
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
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showGroupDialog(context, true),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Group'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showGroupDialog(context, false),
                  icon: const Icon(Icons.link),
                  label: const Text('Join Group'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, Group group, GroupProvider groupProvider) {

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () {
          // Navigate to group detail screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupDetailScreen(group: group),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      group.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Delete button
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade400,
                          size: 20,
                        ),
                        onPressed: () => _showDeleteConfirmation(context, group, groupProvider),
                        tooltip: 'Delete Group',
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoChip(
                    context,
                    Icons.people,
                    '${group.members.length} members',
                    Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    context,
                    Icons.receipt,
                    '${group.expenses.length} expenses',
                    Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildPersonalBalanceSection(context, group, groupProvider),
              const SizedBox(height: 16),
              Text(
                'Members: ${group.members.map((p) => p.name).join(', ')}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showGroupDialog(BuildContext context, bool isCreateMode) {
    showDialog(
      context: context,
      builder: (context) => GroupDialog(initialCreateMode: isCreateMode),
    ).then((result) {
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group operation completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _showDeleteConfirmation(BuildContext context, Group group, GroupProvider groupProvider) {
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
                groupProvider.removeGroup(group.id);
                
                // Show success message
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Group "${group.name}" deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                
                // Try to delete from API in background (don't wait for it)
                final syncService = SyncService();
                syncService.deleteGroupOffline(group.id, context, groupProvider).catchError((e) {
                  print('Background API deletion failed: $e');
                  // Don't show error to user since local deletion succeeded
                });
                
              } catch (e) {
                print('Error deleting group: $e');
                if (context.mounted) {
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
  
  Widget _buildPersonalBalanceSection(BuildContext context, Group group, GroupProvider groupProvider) {
    final userMember = groupProvider.getUserMember(group.id);
    final personalBalance = groupProvider.getUserPersonalBalance(group.id);
    
    if (userMember == null) {
      // User hasn't selected which member they are yet
      return InkWell(
        onTap: () => _showMemberSelectionDialog(context, group, groupProvider),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.orange.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tap to select which member you are',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.orange.shade600,
                size: 16,
              ),
            ],
          ),
        ),
      );
    }
    
    // User has selected a member, show personal balance
    final isPositive = personalBalance != null && personalBalance > 0;
    final balanceColor = isPositive ? Colors.green : Colors.red;
    
    return InkWell(
      onTap: () => _showMemberSelectionDialog(context, group, groupProvider),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Balance',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${userMember.name}',
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Balance',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${isPositive ? '+' : ''}\$${personalBalance?.toStringAsFixed(2) ?? '0.00'}',
                    style: TextStyle(
                      color: balanceColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
  
  void _showMemberSelectionDialog(BuildContext context, Group group, GroupProvider groupProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Your Member in ${group.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Which member are you in this group?',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ...group.members.map((member) {
              return RadioListTile<String>(
                title: Text(member.name),
                value: member.id,
                groupValue: groupProvider.getUserMemberId(group.id),
                onChanged: (value) async {
                  if (value != null) {
                    await groupProvider.setUserMember(group.id, value);
                    Navigator.of(context).pop();
                    
                    // Show success message
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('You are now ${member.name} in ${group.name}'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
