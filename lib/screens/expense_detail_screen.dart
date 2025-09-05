/**
 * File: expense_detail_screen.dart
 * Description: Expense detail screen, shows the details of an expense
 * Author: Sergey Komarov
 * Date: 2025-09-05
 */


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../models/expense.dart';
import '../models/group.dart';
import '../services/image_service.dart';
import '../services/auth_service.dart';
import 'add_expense_screen.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class ExpenseDetailScreen extends StatelessWidget {
  final Expense expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(expense.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit expense screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddExpenseScreen(expenseToEdit: expense),
                ),
              );
            },
            tooltip: 'Edit Expense',
          ),
        ],
      ),
      body: Consumer<GroupProvider>(
        builder: (context, groupProvider, child) {
          final group = groupProvider.currentGroup;
          if (group == null) {
            return const Center(
              child: Text('No group selected'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic Info Card
                _buildBasicInfoCard(expense, group),
                const SizedBox(height: 16),
                
                // Payment Details Card
                _buildPaymentDetailsCard(expense, group),
                const SizedBox(height: 16),
                
                // Split Details Card
                _buildSplitDetailsCard(expense, group),
                const SizedBox(height: 16),
                
                // Images Card (if any)
                if (expense.images != null && expense.images!.isNotEmpty)
                  _buildImagesCard(expense),
                if (expense.images != null && expense.images!.isNotEmpty)
                  const SizedBox(height: 16),
                
                // Metadata Card
                _buildMetadataCard(expense),
              ],
            ),
          );
        },
      ),
    );
  }

  // Builds the Basic Info Card
  Widget _buildBasicInfoCard(Expense expense, Group group) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt,
                  color: Colors.blue.shade400,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Basic Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Name', expense.name),
            _buildInfoRow('Amount', '${expense.currency} ${expense.amount.toStringAsFixed(2)}'),
            if (expense.category != null)
              _buildInfoRow('Category', expense.category!),
            _buildInfoRow('Date', DateFormat('MMM dd, yyyy').format(expense.date)),
            if (expense.exchangeRate != null && expense.exchangeRate != 1.0)
              _buildInfoRow('Exchange Rate', expense.exchangeRate!.toStringAsFixed(4)),
          ],
        ),
      ),
    );
  }

  // Builds the Payment Details Card
  Widget _buildPaymentDetailsCard(Expense expense, Group group) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payment,
                  color: Colors.green.shade400,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Payment Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (expense.customPaidBy != null && expense.customPaidBy!.isNotEmpty) ...[
              // Multiple payers
              Text(
                'Paid by multiple people:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              ...expense.customPaidBy!.entries
                  .where((entry) => entry.value > 0)
                  .map((entry) {
                final person = group.members.firstWhere(
                  (p) => p.id == entry.key,
                  orElse: () => group.members.first, // Fallback to first member if not found
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(person.name),
                      Text(
                        '${expense.currency} ${entry.value.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }),
            ] else ...[
              // Single payer
              Builder(
                builder: (context) {
                  final payer = group.members.firstWhere(
                    (p) => p.id == expense.paidBy || p.name == expense.paidBy,
                    orElse: () => group.members.first, // Fallback to first member if not found
                  );
                  return Column(
                    children: [
                      _buildInfoRow('Paid by', payer.name),
                      _buildInfoRow('Amount paid', '${expense.currency} ${expense.amount.toStringAsFixed(2)}'),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Builds the Split Details Card
  Widget _buildSplitDetailsCard(Expense expense, Group group) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.people,
                  color: Colors.orange.shade400,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Split Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Split between', '${expense.splitBetween.length} people'),
            
            if (expense.customShares != null && expense.customShares!.isNotEmpty) ...[
              // Custom shares
              const SizedBox(height: 12),
              Text(
                'Custom shares:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              ...expense.customShares!.entries.map((entry) {
                final person = group.members.firstWhere(
                  (p) => p.id == entry.key,
                  orElse: () => group.members.first, // Fallback to first member if not found
                );
                final totalShares = expense.customShares!.values.reduce((a, b) => a + b);
                final personAmount = (entry.value / totalShares) * expense.amount;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${person.name} (${entry.value} shares)'),
                      Text(
                        '${expense.currency} ${personAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }),
            ] else ...[
              // Equal split
              const SizedBox(height: 12),
              Text(
                'Equal split:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              ...expense.splitBetween.map((personId) {
                final person = group.members.firstWhere(
                  (p) => p.id == personId || p.name == personId,
                  orElse: () => group.members.first, // Fallback to first member if not found
                );
                final splitAmount = expense.amount / expense.splitBetween.length;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(person.name),
                      Text(
                        '${expense.currency} ${splitAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  // Builds the Images Card
  Widget _buildImagesCard(Expense expense) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                  'Images (${expense.images!.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: expense.images!.length,
              itemBuilder: (context, index) {
                final filename = expense.images![index];
                return GestureDetector(
                  onTap: () => _showImageDialog(context, filename),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _AuthenticatedImage(filename: filename),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Builds the Metadata Card
  Widget _buildMetadataCard(Expense expense) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info,
                  color: Colors.grey.shade400,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Metadata',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Expense ID', expense.id),
            if (expense.createdAt != null)
              _buildInfoRow('Created', DateFormat('MMM dd, yyyy HH:mm').format(expense.createdAt!)),
            if (expense.updatedAt != null)
              _buildInfoRow('Updated', DateFormat('MMM dd, yyyy HH:mm').format(expense.updatedAt!)),
            if (expense.version != null)
              _buildInfoRow('Version', expense.version.toString()),
          ],
        ),
      ),
    );
  }

  // Builds the Info Row
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Shows the image source dialog
  void _showImageDialog(BuildContext context, String filename) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Image'),
                backgroundColor: Colors.transparent,
                elevation: 0,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Expanded(
                child: InteractiveViewer(
                  child: _AuthenticatedImage(filename: filename),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget for displaying images that require authentication
class _AuthenticatedImage extends StatefulWidget {
  final String filename;
  
  const _AuthenticatedImage({required this.filename});
  
  @override
  State<_AuthenticatedImage> createState() => _AuthenticatedImageState();
}

// State for the _AuthenticatedImage widget
class _AuthenticatedImageState extends State<_AuthenticatedImage> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadImage();
  }
  
  Future<void> _loadImage() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      // Get authentication token
      final token = await AuthService.getToken();
      if (token == null) {
        setState(() {
          _error = 'Authentication required';
          _isLoading = false;
        });
        return;
      }
      
      // Make authenticated request to get image
      final imageUrl = ImageService.getImageUrl(widget.filename);
      final response = await http.get(
        Uri.parse(imageUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'image/*',
        },
      );
      
      if (response.statusCode == 200) {
        setState(() {
          _imageBytes = response.bodyBytes;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load image (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading image: $e';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_error != null) {
      return Container(
        color: Colors.grey.shade200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    if (_imageBytes != null) {
      return Image.memory(
        _imageBytes!,
        fit: BoxFit.cover,
      );
    }
    
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey,
        ),
      ),
    );
  }
}
