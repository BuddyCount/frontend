import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';

class GroupDialog extends StatefulWidget {
  const GroupDialog({super.key});

  @override
  State<GroupDialog> createState() => _GroupDialogState();
}

class _GroupDialogState extends State<GroupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final _memberNamesController = TextEditingController();
  final _inviteLinkController = TextEditingController();
  
  bool _isCreatingGroup = true;
  bool _isLoading = false;

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
      content: Form(
        key: _formKey,
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
            ],
          ],
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
        
        // Use offline-first approach
        final syncService = SyncService();
        await syncService.createGroupOffline(
          _groupNameController.text.trim(),
          memberNames,
          context,
        );
        
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Group created successfully! You can now switch between groups.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        // For joining groups, we'll still try the API first
        try {
          final result = await ApiService.joinGroup(_inviteLinkController.text.trim());
          
          if (mounted) {
            Navigator.of(context).pop(result);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Joined group "${result['name']}" successfully!')),
            );
          }
        } catch (e) {
          // If API fails, show offline message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unable to join group while offline. Please try again when connected.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
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
}
