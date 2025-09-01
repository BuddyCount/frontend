import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../models/expense.dart';
import '../services/api_service.dart';

import 'package:intl/intl.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCurrency = 'USD';
  String _selectedPayer = '';
  DateTime _selectedDate = DateTime.now();
  final List<String> _selectedMembers = [];
  
  // Custom split mode
  bool _isCustomSplitMode = false;
  Map<String, double> _customShares = {}; // memberId -> share amount
  
  // Custom paid by mode
  bool _isCustomPaidByMode = false;
  Map<String, double> _customPaidBy = {}; // memberId -> amount paid
  String _selectedCategory = 'FOOD';
  final TextEditingController _exchangeRateController = TextEditingController(text: '1.0');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      if (groupProvider.currentGroup != null) {
        // Try to auto-fill with user's selected member
        final userMember = groupProvider.getUserMember(groupProvider.currentGroup!.id);
        
        if (userMember != null) {
          _selectedPayer = userMember.id;
          print('Auto-filled payer with user member: ${userMember.name}');
        } else {
          // Fallback to first member if user hasn't selected one
          _selectedPayer = groupProvider.currentGroup!.members.first.id;
          print('No user member selected, using first member as payer');
        }
        
        // Auto-fill currency and exchange rate based on group
        _selectedCurrency = groupProvider.currentGroup!.currency;
        if (_selectedCurrency != groupProvider.currentGroup!.currency) {
          // Different currency, set exchange rate to 1.0 as default
          _exchangeRateController.text = '1.0';
          print('Different currency detected, set default exchange rate to 1.0');
        }
        
        for (var person in groupProvider.currentGroup!.members) {
          _selectedMembers.add(person.id);
        }
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Expense Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an expense name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _amountController,
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an amount';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
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
                              
                              // Auto-update exchange rate when currency changes
                              if (value != null) {
                                final currentGroup = Provider.of<GroupProvider>(context, listen: false).currentGroup;
                                if (currentGroup != null && value != currentGroup.currency) {
                                  // Different currency, set exchange rate to 1.0 as default
                                  _exchangeRateController.text = '1.0';
                                  print('Currency changed to $value, set default exchange rate to 1.0');
                                } else if (value == currentGroup?.currency) {
                                  // Same currency, set exchange rate to 1.0
                                  _exchangeRateController.text = '1.0';
                                  print('Currency matches group currency, set exchange rate to 1.0');
                                }
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'FOOD', child: Text('Food')),
                            DropdownMenuItem(value: 'TRANSPORT', child: Text('Transport')),
                            DropdownMenuItem(value: 'ENTERTAINMENT', child: Text('Entertainment')),
                            DropdownMenuItem(value: 'SHOPPING', child: Text('Shopping')),
                            DropdownMenuItem(value: 'BILLS', child: Text('Bills')),
                            DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _exchangeRateController,
                          decoration: const InputDecoration(
                            labelText: 'Exchange Rate',
                            border: OutlineInputBorder(),
                            helperText: '1.0 = same currency',
                          ),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter exchange rate';
                            }
                            final rate = double.tryParse(value);
                            if (rate == null || rate <= 0) {
                              return 'Please enter a valid positive number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Paid by section
                  Text(
                    'Paid by:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  
                  // Paid by mode toggle
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Payment Mode:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('Single'),
                            icon: Icon(Icons.person),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Multiple'),
                            icon: Icon(Icons.group),
                          ),
                        ],
                        selected: {_isCustomPaidByMode},
                        onSelectionChanged: (Set<bool> newSelection) {
                          setState(() {
                            _isCustomPaidByMode = newSelection.first;
                            if (_isCustomPaidByMode) {
                              // Initialize custom paid by amounts
                              final totalAmount = double.tryParse(_amountController.text) ?? 0.0;
                              final memberCount = currentGroup.members.length;
                              final equalAmount = totalAmount / memberCount;
                              for (final member in currentGroup.members) {
                                _customPaidBy[member.id] = equalAmount;
                              }
                            } else {
                              // Clear custom paid by when switching to single mode
                              _customPaidBy.clear();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  
                  // Single payer dropdown (only visible in single mode)
                  if (!_isCustomPaidByMode) ...[
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPayer.isEmpty ? null : _selectedPayer,
                      decoration: const InputDecoration(
                        labelText: 'Who paid',
                        border: OutlineInputBorder(),
                      ),
                      items: currentGroup.members.map((person) {
                        return DropdownMenuItem(
                          value: person.id,
                          child: Text(person.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPayer = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select who paid';
                        }
                        return null;
                      },
                    ),
                  ],
                  
                  // Multiple payers input (only visible in multiple mode)
                  if (_isCustomPaidByMode) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Amount paid by each person:',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...currentGroup.members.map((person) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(person.name),
                            ),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                initialValue: _customPaidBy[person.id]?.toString() ?? '0.0',
                                decoration: const InputDecoration(
                                  labelText: 'Amount',
                                  border: OutlineInputBorder(),
                                  hintText: '0.0',
                                ),
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Enter amount';
                                  }
                                  final amount = double.tryParse(value);
                                  if (amount == null || amount < 0) {
                                    return 'Valid positive number';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  final amount = double.tryParse(value);
                                  if (amount != null && amount >= 0) {
                                    setState(() {
                                      _customPaidBy[person.id] = amount;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    Consumer<GroupProvider>(
                      builder: (context, groupProvider, child) {
                        final totalPaid = _customPaidBy.values.fold(0.0, (sum, amount) => sum + amount);
                        final totalExpense = double.tryParse(_amountController.text) ?? 0.0;
                        final difference = totalPaid - totalExpense;
                        
                        return Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: difference.abs() < 0.01 ? Colors.green.shade50 : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: difference.abs() < 0.01 ? Colors.green.shade200 : Colors.orange.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                difference.abs() < 0.01 ? Icons.check_circle : Icons.warning,
                                color: difference.abs() < 0.01 ? Colors.green : Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Total paid: \$${totalPaid.toStringAsFixed(2)} | '
                                  'Expense: \$${totalExpense.toStringAsFixed(2)} | '
                                  'Difference: \$${difference.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: difference.abs() < 0.01 ? Colors.green.shade700 : Colors.orange.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Split between:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...currentGroup.members.map((person) {
                    return CheckboxListTile(
                      title: Text(person.name),
                      value: _selectedMembers.contains(person.id),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedMembers.add(person.id);
                            // Initialize custom share to 1.0 when adding member
                            if (_isCustomSplitMode) {
                              _customShares[person.id] = 1.0;
                            }
                          } else {
                            _selectedMembers.remove(person.id);
                            // Remove custom share when removing member
                            _customShares.remove(person.id);
                          }
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                  
                  // Custom split mode toggle
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Split Mode:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('Equal'),
                            icon: Icon(Icons.equalizer),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Custom'),
                            icon: Icon(Icons.tune),
                          ),
                        ],
                        selected: {_isCustomSplitMode},
                        onSelectionChanged: (Set<bool> newSelection) {
                          setState(() {
                            _isCustomSplitMode = newSelection.first;
                            if (_isCustomSplitMode) {
                              // Initialize custom shares for selected members
                              for (final memberId in _selectedMembers) {
                                _customShares[memberId] = 1.0;
                              }
                            } else {
                              // Clear custom shares when switching to equal mode
                              _customShares.clear();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  
                  // Custom shares input (only visible in custom mode)
                  if (_isCustomSplitMode) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Custom Shares:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the share amount for each member (e.g., 2.0, 0.5)',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...currentGroup.members
                        .where((person) => _selectedMembers.contains(person.id))
                        .map((person) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(person.name),
                            ),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                initialValue: _customShares[person.id]?.toString() ?? '1.0',
                                decoration: const InputDecoration(
                                  labelText: 'Shares',
                                  border: OutlineInputBorder(),
                                  hintText: '1.0',
                                ),
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Enter shares';
                                  }
                                  final shares = double.tryParse(value);
                                  if (shares == null || shares <= 0) {
                                    return 'Valid positive number';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  final shares = double.tryParse(value);
                                  if (shares != null && shares > 0) {
                                    setState(() {
                                      _customShares[person.id] = shares;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Date'),
                    subtitle: Text(
                      DateFormat('MMM dd, yyyy').format(_selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDate = date;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedMembers.isEmpty
                          ? null
                          : () => _saveExpense(groupProvider),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Save Expense',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

    void _saveExpense(GroupProvider groupProvider) async {
    if (_formKey.currentState!.validate() && _selectedMembers.isNotEmpty) {
      final currentGroup = groupProvider.currentGroup;
      if (currentGroup == null) return;
      
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Creating expense...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      try {
        // Try to create expense via API first (online-first approach)
        final apiResponse = await ApiService.createExpense(
          groupId: currentGroup.id,
          name: _nameController.text,
          amount: double.parse(_amountController.text),
          currency: _selectedCurrency,
          paidByPersonId: _selectedPayer,
          splitBetweenPersonIds: _selectedMembers,
          category: _selectedCategory,
          exchangeRate: double.parse(_exchangeRateController.text),
          date: _selectedDate,
          customShares: _isCustomSplitMode ? _customShares : null,
          customPaidBy: _isCustomPaidByMode ? _customPaidBy : null,
        );
        
        // Create local expense object from API response
        final expense = Expense(
          id: apiResponse['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          name: apiResponse['name'] ?? _nameController.text,
          amount: (apiResponse['amount'] as num?)?.toDouble() ?? double.parse(_amountController.text),
          currency: apiResponse['currency'] ?? _selectedCurrency,
          paidBy: _selectedPayer,
          splitBetween: _selectedMembers,
          date: _selectedDate,
          groupId: currentGroup.id,
          category: _selectedCategory,
          exchangeRate: double.parse(_exchangeRateController.text),
          createdAt: apiResponse['createdAt'] != null ? DateTime.parse(apiResponse['createdAt']) : null,
          updatedAt: apiResponse['updatedAt'] != null ? DateTime.parse(apiResponse['updatedAt']) : null,
          version: apiResponse['version'],
          customShares: _isCustomSplitMode ? _customShares : null,
          customPaidBy: _isCustomPaidByMode ? _customPaidBy : null,
        );

        // Add to local storage and provider
        groupProvider.addExpense(expense);
        
        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        Navigator.pop(context);
        
      } catch (e) {
        print('Error creating expense via API: $e');
        
        // Fallback to offline creation
        try {
          // Create expense locally with generated ID
          final expense = Expense(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: _nameController.text,
            amount: double.parse(_amountController.text),
            currency: _selectedCurrency,
            paidBy: _selectedPayer,
            splitBetween: _selectedMembers,
            date: _selectedDate,
            groupId: currentGroup.id,
            category: _selectedCategory,
            exchangeRate: double.parse(_exchangeRateController.text),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
                      version: 1,
          customShares: _isCustomSplitMode ? _customShares : null,
          customPaidBy: _isCustomPaidByMode ? _customPaidBy : null,
          );

          // Add to local storage and provider
          groupProvider.addExpense(expense);
          
          // Show offline success message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Expense created offline. Will sync when online.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
          
          Navigator.pop(context);
          
        } catch (offlineError) {
          print('Error creating expense offline: $offlineError');
          
          // Show error message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to create expense: ${offlineError.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }



  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _exchangeRateController.dispose();
    super.dispose();
  }
} 