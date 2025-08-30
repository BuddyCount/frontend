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
                  DropdownButtonFormField<String>(
                    initialValue: _selectedPayer.isEmpty ? null : _selectedPayer,
                    decoration: const InputDecoration(
                      labelText: 'Paid by',
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
                          } else {
                            _selectedMembers.remove(person.id);
                          }
                        });
                      },
                    );
                  }),
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
        // Create expense via API
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
        print('Error creating expense: $e');
        
        // Show error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create expense: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
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