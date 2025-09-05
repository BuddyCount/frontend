import 'package:flutter/material.dart';

import '../models/person.dart';
import '../services/sync_service.dart';

class GroupDialog extends StatefulWidget {
  final bool initialCreateMode;
  
  const GroupDialog({
    super.key,
    this.initialCreateMode = true,
  });

  @override
  State<GroupDialog> createState() => _GroupDialogState();
}

class _GroupDialogState extends State<GroupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _memberNamesController = TextEditingController();
  final _inviteLinkController = TextEditingController();
  
  late bool _isCreatingGroup;
  bool _isLoading = false;
  String? _selectedMemberId;
  List<Person> _availableMembers = [];
  String _selectedCurrency = 'USD';

  @override
  void initState() {
    super.initState();
    _isCreatingGroup = widget.initialCreateMode;
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _memberNamesController.dispose();
    _inviteLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isCreatingGroup ? 'Create New Group' : 'Join Existing Group'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            // Toggle between create and join
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Create')),
                ButtonSegment(value: false, label: Text('Join')),
              ],
              selected: {_isCreatingGroup},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  _isCreatingGroup = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 20),
            
            if (_isCreatingGroup) ...[
              // Create group form
              TextFormField(
                controller: _groupNameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a group name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Family group, Work team, etc.',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCurrency,
                decoration: const InputDecoration(
                  labelText: 'Currency',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'USD', child: Text('USD')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                  DropdownMenuItem(value: 'CHF', child: Text('CHF')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCurrency = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _memberNamesController,
                decoration: const InputDecoration(
                  labelText: 'Member Names (comma separated)',
                  border: OutlineInputBorder(),
                  hintText: 'Alice, Bob, Charlie',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter at least one member name';
                  }
                  return null;
                },
              ),
            ] else ...[
              // Join group form
              TextFormField(
                controller: _inviteLinkController,
                decoration: const InputDecoration(
                  labelText: 'Invite Link',
                  border: OutlineInputBorder(),
                  hintText: 'https://buddycount.app/join/abc123',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an invite link';
                  }
                  final uri = Uri.tryParse(value);
                  if (uri == null || !uri.hasAbsolutePath) {
                    return 'Please enter a valid URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Member selection for the current user
              _buildMemberSelection(),
            ],
          ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isCreatingGroup ? 'Create' : 'Join'),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isCreatingGroup) {
        final memberNames = _memberNamesController.text
            .split(',')
            .map((name) => name.trim())
            .where((name) => name.isNotEmpty)
            .toList();
        
        // Use enhanced sync service (online-first, offline-fallback)
        final syncService = SyncService();
        await syncService.createGroupOffline(
          _groupNameController.text.trim(),
          memberNames,
          context,
          description: _descriptionController.text.trim(),
          currency: _selectedCurrency,
        );
        
        if (mounted) {
          Navigator.of(context).pop();
          
          // Show appropriate message based on connectivity
          final isOnline = syncService.isOnline;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isOnline 
                  ? '✅ Group created successfully via backend! You can now switch between groups.'
                  : '📱 Group created offline! Will sync with backend when connection is restored.',
              ),
              backgroundColor: isOnline ? Colors.green : Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        // For joining groups, use enhanced sync service
        final syncService = SyncService();
        await syncService.joinGroupOffline(
          _inviteLinkController.text.trim(),
          context,
        );
        
        if (mounted) {
          Navigator.of(context).pop();
          
          // Show appropriate message based on connectivity
          final isOnline = syncService.isOnline;
          if (isOnline) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Group joined successfully! You can now switch to the group.'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          // Offline message is handled by the sync service
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Widget _buildMemberSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Which member are you?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        if (_isCreatingGroup) ...[
          // For creating groups, show member names from input
          if (_memberNamesController.text.isNotEmpty) ...[
            ..._parseMemberNames().map((memberName) {
              return RadioListTile<String>(
                title: Text(memberName),
                value: memberName,
                groupValue: _selectedMemberId,
                onChanged: (value) {
                  setState(() {
                    _selectedMemberId = value;
                  });
                },
              );
            }),
          ] else ...[
            Text(
              'Enter member names above first',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ] else ...[
          // For joining groups, show available members
          if (_availableMembers.isNotEmpty) ...[
            ..._availableMembers.map((member) {
              return RadioListTile<String>(
                title: Text(member.name),
                value: member.id,
                groupValue: _selectedMemberId,
                onChanged: (value) {
                  setState(() {
                    _selectedMemberId = value;
                  });
                },
              );
            }),
          ] else ...[
            Text(
              'Members will be loaded when joining the group',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ],
    );
  }
  
  List<String> _parseMemberNames() {
    return _memberNamesController.text
        .split(',')
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
  }
}
