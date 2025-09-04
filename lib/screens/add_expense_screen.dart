import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/group_provider.dart';
import '../models/expense.dart';
import '../services/api_service.dart';
import '../services/image_service.dart';
import '../services/auth_service.dart';

import 'package:intl/intl.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expenseToEdit; // Optional expense to edit
  
  const AddExpenseScreen({super.key, this.expenseToEdit});

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
  
  // Images
  final List<XFile> _selectedImages = [];
  final List<String> _uploadedImageFilenames = [];
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
        final exchangeRate = _getExchangeRatePlaceholder(_selectedCurrency, groupProvider.currentGroup!.currency);
        _exchangeRateController.text = exchangeRate;
        print('Set exchange rate to: $exchangeRate for ${_selectedCurrency} -> ${groupProvider.currentGroup!.currency}');
        
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
      body: Consumer<GroupProvider>(
        builder: (context, groupProvider, child) {
          final currentGroup = groupProvider.currentGroup;
          
          if (currentGroup == null) {
            return const Center(
              child: Text('No group selected'),
            );
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade50,
                  Colors.purple.shade50,
                  Colors.pink.shade50,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Custom App Bar with gradient
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.purple.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.receipt_long,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Add New Expense',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'for ${currentGroup.name}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.attach_money,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Form Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
            key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                            // Expense Name Card
                            _buildExpenseNameCard(),
                            const SizedBox(height: 20),
                            
                            // Amount & Currency Card
                            _buildAmountCurrencyCard(),
                            const SizedBox(height: 20),
                            
                            // Category & Exchange Rate Card
                            _buildCategoryExchangeCard(),
                            const SizedBox(height: 20),
                            
                            // Images Card
                            _buildImagesCard(),
                            const SizedBox(height: 20),
                            
                            // Date Card
                            _buildDateCard(),
                            const SizedBox(height: 20),
                            
                            // Payment Mode Card
                            _buildPaymentModeCard(),
                            const SizedBox(height: 20),
                            
                            // Custom Paid By Card (if in multiple payment mode)
                            if (_isCustomPaidByMode) ...[
                              _buildCustomPaidByCard(),
                              const SizedBox(height: 20),
                            ],
                            
                            // Split Mode Card
                            _buildSplitModeCard(),
                            const SizedBox(height: 20),
                            
                            // Custom Shares Card (if in custom split mode)
                            if (_isCustomSplitMode) ...[
                              _buildCustomSharesCard(),
                              const SizedBox(height: 20),
                            ],
                            
                            // Members Selection Card
                            _buildMembersSelectionCard(),
                            const SizedBox(height: 20),
                            
                            // Save Button
                            _buildSaveButton(),
                            const SizedBox(height: 20),
                          ],
                        ),
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

  Widget _buildExpenseNameCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.edit_note,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Expense Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
      controller: _nameController,
            decoration: InputDecoration(
              labelText: 'What did you spend on?',
              hintText: 'e.g., Dinner at restaurant, Gas, Groceries',
              prefixIcon: Icon(Icons.receipt, color: Colors.blue.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
      ),
      validator: (value) {
              if (value == null || value.isEmpty) {
          return 'Please enter an expense name';
        }
        return null;
      },
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCurrencyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade100,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.attach_money,
                  color: Colors.green.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Amount & Currency',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
      controller: _amountController,
                  decoration: InputDecoration(
        labelText: 'Amount',
                    prefixIcon: Icon(Icons.monetization_on, color: Colors.green.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.green.shade400, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
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
                            const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
      value: _selectedCurrency,
                  decoration: InputDecoration(
        labelText: 'Currency',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.green.shade400, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
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
          final currentGroup = Provider.of<GroupProvider>(context, listen: false).currentGroup;
          if (currentGroup != null) {
            final exchangeRate = _getExchangeRatePlaceholder(value, currentGroup.currency);
            _exchangeRateController.text = exchangeRate;
          } else {
            _exchangeRateController.text = '1.0';
          }
        });
      },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryExchangeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.shade100,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.category,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Category & Exchange Rate',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.orange.shade400, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'FOOD', child: Text('Food')),
                    DropdownMenuItem(value: 'TRANSPORT', child: Text('Transport')),
                    DropdownMenuItem(value: 'HOUSING', child: Text('Housing')),
                    DropdownMenuItem(value: 'UTILITIES', child: Text('Utilities')),
                    DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Consumer<GroupProvider>(
                  builder: (context, groupProvider, child) {
                    final currentGroup = groupProvider.currentGroup;
                    final hintText = currentGroup != null 
                        ? '1 ${_selectedCurrency} = ? ${currentGroup.currency}'
                        : 'Exchange Rate';
                    
                    return TextFormField(
                      controller: _exchangeRateController,
                      decoration: InputDecoration(
                        labelText: 'Exchange Rate',
                        hintText: hintText,
                        prefixIcon: Icon(Icons.trending_up, color: Colors.orange.shade400),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.orange.shade400, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter exchange rate';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.shade100,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: Colors.purple.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Date',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(15),
                color: Colors.grey.shade50,
              ),
              child: Row(
                children: [
                  Icon(Icons.event, color: Colors.purple.shade400),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('MMM dd, yyyy').format(_selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_drop_down, color: Colors.purple.shade400),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentModeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade100,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.payment,
                  color: Colors.teal.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Payment Mode',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(
                value: false,
                label: Text('Single Payer'),
                icon: Icon(Icons.person),
              ),
              ButtonSegment<bool>(
                value: true,
                label: Text('Multiple Payers'),
                icon: Icon(Icons.people),
              ),
            ],
            selected: {_isCustomPaidByMode},
            onSelectionChanged: (Set<bool> selection) {
              setState(() {
                _isCustomPaidByMode = selection.first;
                if (!_isCustomPaidByMode) {
                  _customPaidBy.clear();
                }
              });
            },
          ),
          const SizedBox(height: 16),
          if (!_isCustomPaidByMode) ...[
            Consumer<GroupProvider>(
              builder: (context, groupProvider, child) {
                final currentGroup = groupProvider.currentGroup;
                if (currentGroup == null) return const SizedBox.shrink();
                
    return DropdownButtonFormField<String>(
                  value: _selectedPayer.isNotEmpty ? _selectedPayer : null,
                                    decoration: InputDecoration(
        labelText: 'Paid by',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
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
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSplitModeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.shade100,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.share,
                  color: Colors.indigo.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Split Mode',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(
                value: false,
                label: Text('Equal Split'),
                icon: Icon(Icons.equalizer),
              ),
              ButtonSegment<bool>(
                value: true,
                label: Text('Custom Shares'),
                icon: Icon(Icons.tune),
              ),
            ],
            selected: {_isCustomSplitMode},
                        onSelectionChanged: (Set<bool> selection) {
          setState(() {
                _isCustomSplitMode = selection.first;
                if (!_isCustomSplitMode) {
                  _customShares.clear();
                } else {
                  // Initialize custom shares for all selected members
                  for (final memberId in _selectedMembers) {
                    if (!_customShares.containsKey(memberId)) {
                      _customShares[memberId] = 1.0;
                    }
                  }
                }
              });
            },
        ),
        ],
      ),
    );
  }

  Widget _buildMembersSelectionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.shade100,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.pink.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.people,
                  color: Colors.pink.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
        const Text(
                'Split Between',
          style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Select All / Unselect All buttons
          Consumer<GroupProvider>(
            builder: (context, groupProvider, child) {
              final currentGroup = groupProvider.currentGroup;
              if (currentGroup == null) return const SizedBox.shrink();
              
              final allSelected = _selectedMembers.length == currentGroup.members.length;
              final someSelected = _selectedMembers.isNotEmpty;
              
              return Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: allSelected ? null : _selectAllMembers,
                      icon: Icon(
                        Icons.check_box,
                        color: allSelected ? Colors.grey : Colors.pink.shade400,
                        size: 18,
                      ),
                      label: Text(
                        'Select All',
                        style: TextStyle(
                          color: allSelected ? Colors.grey : Colors.pink.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: allSelected ? Colors.grey.shade200 : Colors.pink.shade50,
                        foregroundColor: allSelected ? Colors.grey : Colors.pink.shade400,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: allSelected ? Colors.grey.shade300 : Colors.pink.shade200,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: !someSelected ? null : _unselectAllMembers,
                      icon: Icon(
                        Icons.check_box_outline_blank,
                        color: !someSelected ? Colors.grey : Colors.pink.shade400,
                        size: 18,
                      ),
                      label: Text(
                        'Unselect All',
                        style: TextStyle(
                          color: !someSelected ? Colors.grey : Colors.pink.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !someSelected ? Colors.grey.shade200 : Colors.pink.shade50,
                        foregroundColor: !someSelected ? Colors.grey : Colors.pink.shade400,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: !someSelected ? Colors.grey.shade300 : Colors.pink.shade200,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 16),
          Consumer<GroupProvider>(
            builder: (context, groupProvider, child) {
              final currentGroup = groupProvider.currentGroup;
              if (currentGroup == null) return const SizedBox.shrink();
              
              return Column(
                children: currentGroup.members.map((person) {
                  final isSelected = _selectedMembers.contains(person.id);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.pink.shade50 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.pink.shade300 : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: CheckboxListTile(
                      title: Text(
                        person.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.pink.shade700 : Colors.black87,
                        ),
                      ),
                      value: isSelected,
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                            _selectedMembers.add(person.id);
                            // Initialize custom share for new member if in custom split mode
                            if (_isCustomSplitMode && !_customShares.containsKey(person.id)) {
                              _customShares[person.id] = 1.0;
                            }
              } else {
                            _selectedMembers.remove(person.id);
                            // Remove custom share for deselected member
                            _customShares.remove(person.id);
              }
            });
          },
                      activeColor: Colors.pink.shade400,
                      checkColor: Colors.white,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCustomSharesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.shade100,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.tune,
                  color: Colors.amber.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Custom Shares',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Consumer<GroupProvider>(
            builder: (context, groupProvider, child) {
              final currentGroup = groupProvider.currentGroup;
              if (currentGroup == null) return const SizedBox.shrink();
              
              // Ensure all selected members have custom shares initialized
              for (final memberId in _selectedMembers) {
                if (!_customShares.containsKey(memberId)) {
                  _customShares[memberId] = 1.0;
                }
              }
              
              return Column(
                children: _selectedMembers.map((memberId) {
                  final person = currentGroup.members.firstWhere((p) => p.id == memberId);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      initialValue: _customShares[memberId]?.toString() ?? '1.0',
                      decoration: InputDecoration(
                        labelText: '${person.name} shares',
                        prefixIcon: Icon(Icons.person, color: Colors.amber.shade400),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.amber.shade400, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final shareValue = double.tryParse(value);
                        if (shareValue != null) {
                          _customShares[memberId] = shareValue;
                        }
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCustomPaidByCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.shade100,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.cyan.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.payment,
                  color: Colors.cyan.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Custom Payment Amounts',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Consumer<GroupProvider>(
            builder: (context, groupProvider, child) {
              final currentGroup = groupProvider.currentGroup;
              if (currentGroup == null) return const SizedBox.shrink();
              
              return Column(
                children: currentGroup.members.map((person) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      initialValue: _customPaidBy[person.id]?.toString() ?? '0.0',
                      decoration: InputDecoration(
                        labelText: '${person.name} paid',
                        prefixIcon: Icon(Icons.person_pin, color: Colors.cyan.shade400),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.cyan.shade400, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final amountValue = double.tryParse(value);
                        if (amountValue != null) {
                          _customPaidBy[person.id] = amountValue;
                        }
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.cyan.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyan.shade200),
            ),
            child: Column(
              children: [
                Text(
                  'Payment Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Paid: \$${_customPaidBy.values.fold(0.0, (sum, amount) => sum + amount).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Expense Amount: \$${_amountController.text.isNotEmpty ? _amountController.text : "0.00"}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Difference: \$${(_customPaidBy.values.fold(0.0, (sum, amount) => sum + amount) - (double.tryParse(_amountController.text) ?? 0.0)).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: (_customPaidBy.values.fold(0.0, (sum, amount) => sum + amount) - (double.tryParse(_amountController.text) ?? 0.0)).abs() < 0.01 
                      ? Colors.green 
                      : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
      ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.purple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _saveExpense,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.save,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              'Save Expense',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
        );
    if (picked != null && picked != _selectedDate) {
          setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one person to split with'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Ensure all selected members have custom shares if in custom split mode
    if (_isCustomSplitMode) {
      for (final memberId in _selectedMembers) {
        if (!_customShares.containsKey(memberId)) {
          _customShares[memberId] = 1.0;
        }
      }
    }

    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final currentGroup = groupProvider.currentGroup;
    if (currentGroup == null) return;

    try {
      // Clear any previously uploaded filenames
      _uploadedImageFilenames.clear();
      
      // Get authentication token once and reuse it
      final token = await AuthService.getToken();
      print('🔐 Got token for expense creation: ${token != null ? 'Present' : 'NULL'}');
      
      // Upload images first if any are selected
      if (_selectedImages.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 Uploading images...'),
            duration: Duration(seconds: 2),
          ),
        );
        
        for (final imageFile in _selectedImages) {
          final filename = await ImageService.uploadImage(imageFile, token: token);
          if (filename != null) {
            _uploadedImageFilenames.add(filename);
          }
        }
        
        print('📸 Uploaded ${_uploadedImageFilenames.length} images: $_uploadedImageFilenames');
      }
      
      // Debug: Check if images are being passed to API
      print('🔍 About to create expense with images: $_uploadedImageFilenames');
      print('🔍 Images list is empty: ${_uploadedImageFilenames.isEmpty}');
      
      // Try to create expense via API first
      final expenseData = await ApiService.createExpense(
        groupId: currentGroup.id,
        name: _nameController.text,
        amount: double.parse(_amountController.text),
        currency: _selectedCurrency,
        paidByPersonId: _selectedPayer,
        splitBetweenPersonIds: _selectedMembers,
        category: _selectedCategory,
        exchangeRate: double.parse(_exchangeRateController.text),
        memberNames: currentGroup.members.map((m) => m.name).toList(),
        date: _selectedDate,
        customShares: _isCustomSplitMode ? _customShares : null,
        customPaidBy: _isCustomPaidByMode ? _customPaidBy : null,
        images: _uploadedImageFilenames.isNotEmpty ? _uploadedImageFilenames : null,
      );

      // Extract split information from selected members, excluding the payer
      List<String> splitBetween = [];
      for (final memberId in _selectedMembers) {
        // Skip the payer - they don't split with themselves
        if (memberId == _selectedPayer) continue;
        
        final member = currentGroup.members.firstWhere(
          (m) => m.id == memberId,
          orElse: () => currentGroup.members.first,
        );
        splitBetween.add(member.name);
      }
      
      // Create expense locally from API response
      final expense = Expense(
        id: expenseData['id'].toString(),
        name: expenseData['name'],
        amount: expenseData['amount'].toDouble(),
        currency: expenseData['currency'],
        paidBy: expenseData['paidBy'].toString(),
        splitBetween: splitBetween,
        date: DateTime.parse(expenseData['date']),
        groupId: currentGroup.id,
        category: expenseData['category'],
        exchangeRate: expenseData['exchangeRate']?.toDouble(),
        createdAt: DateTime.parse(expenseData['createdAt']),
        updatedAt: expenseData['updatedAt'] != null ? DateTime.parse(expenseData['updatedAt']) : null,
        version: expenseData['version'],
        customShares: _isCustomSplitMode ? _customShares : null,
        customPaidBy: _isCustomPaidByMode ? _customPaidBy : null,
        images: expenseData['images'] != null ? List<String>.from(expenseData['images']) : null,
      );

      await groupProvider.addExpense(expense);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      if (context.mounted) {
        Navigator.pop(context);
      }
      
    } catch (e) {
      print('Error creating expense via API: $e');
      
      // Fallback to offline creation
      try {
        // Create expense locally with generated ID
        // Extract split information from selected members, excluding the payer
        List<String> splitBetween = [];
        for (final memberId in _selectedMembers) {
          // Skip the payer - they don't split with themselves
          if (memberId == _selectedPayer) continue;
          
          final member = currentGroup.members.firstWhere(
            (m) => m.id == memberId,
            orElse: () => currentGroup.members.first,
          );
          splitBetween.add(member.name);
        }
        
        final expense = Expense(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text,
          amount: double.parse(_amountController.text),
          currency: _selectedCurrency,
          paidBy: _selectedPayer,
          splitBetween: splitBetween,
          date: _selectedDate,
          groupId: currentGroup.id,
          category: _selectedCategory,
          exchangeRate: double.parse(_exchangeRateController.text),
          createdAt: DateTime.now(),
          customShares: _isCustomSplitMode ? _customShares : null,
          customPaidBy: _isCustomPaidByMode ? _customPaidBy : null,
        );

        await groupProvider.addExpense(expense);

        // Show offline success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense created offline (will sync when online)'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        
        if (context.mounted) {
          Navigator.pop(context);
        }
        
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

  Widget _buildImagesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.photo_library,
                color: Colors.purple.shade400,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Images',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Add image button
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showImageSourceDialog,
                  icon: Icon(Icons.add_photo_alternate, color: Colors.white),
                  label: const Text('Add Images', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          
          // Display selected images.
          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Selected Images (${_selectedImages.length}):',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  final image = _selectedImages[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            image.path, // XFile.path works for both web and mobile
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.error),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImages.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }//

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final imageFile = await ImageService.pickImage(source: source);
    if (imageFile != null) {
      setState(() {
        _selectedImages.add(imageFile);
      });
    }
  }

  void _selectAllMembers() {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final currentGroup = groupProvider.currentGroup;
    if (currentGroup == null) return;

    setState(() {
      _selectedMembers.clear();
      for (var person in currentGroup.members) {
        _selectedMembers.add(person.id);
        // Initialize custom share for all members if in custom split mode
        if (_isCustomSplitMode && !_customShares.containsKey(person.id)) {
          _customShares[person.id] = 1.0;
        }
      }
    });
  }

  void _unselectAllMembers() {
    setState(() {
      _selectedMembers.clear();
      _customShares.clear();
    });
  }

  String _getExchangeRatePlaceholder(String selectedCurrency, String groupCurrency) {
    // If same currency, return 1.0
    if (selectedCurrency == groupCurrency) {
      return '1.0';
    }
    
    // Exchange rates based on the provided values
    // 1 CHF = 1.07 Euro, 1 Euro = 0.94 CHF
    // 1 USD = 0.8 CHF, 1 USD = 1.24 USD (this seems wrong, assuming 1 USD = 1.24 CHF)
    // 1 USD = 0.86 Euro, 1 Euro = 1.16 USD
    
    if (groupCurrency == 'CHF') {
      switch (selectedCurrency) {
        case 'EUR':
          return '1.07'; // 1 CHF = 1.07 EUR
        case 'USD':
          return '1.24'; // 1 CHF = 1.24 USD (assuming the 1.24 USD was meant to be CHF to USD)
        default:
          return '1.0';
      }
    } else if (groupCurrency == 'EUR') {
      switch (selectedCurrency) {
        case 'CHF':
          return '0.94'; // 1 EUR = 0.94 CHF
        case 'USD':
          return '1.16'; // 1 EUR = 1.16 USD
        default:
          return '1.0';
      }
    } else if (groupCurrency == 'USD') {
      switch (selectedCurrency) {
        case 'CHF':
          return '0.80'; // 1 USD = 0.80 CHF
        case 'EUR':
          return '0.86'; // 1 USD = 0.86 EUR
        default:
          return '1.0';
      }
    }
    
    return '1.0';
  }
} 
