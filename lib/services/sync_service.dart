/**
 * File: sync_service.dart
 * Description: Sync service, provides methods to sync data with the backend
 * Author: Sergey Komarov
 * Date: 2025-09-05
 */

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'local_storage_service.dart';
import 'api_service.dart';
import '../providers/group_provider.dart';
import '../models/group.dart';
import '../models/person.dart';
import '../models/expense.dart';

// Class for the Sync Service
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();
  
  static const String baseUrl = 'https://api.buddycount.duckdns.org';

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isOnline = false;
  Timer? _syncTimer;

  // Initialize the sync service
  Future<void> initialize(BuildContext context) async {
    // Check initial connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    _isOnline = connectivityResult != ConnectivityResult.none;
    print('🔍 SyncService initialized: _isOnline = $_isOnline, connectivity = $connectivityResult');

    // Listen to connectivity changes
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;
      
      if (!wasOnline && _isOnline) {
        // Just came online - sync pending operations
        _syncPendingOperations(context);
      }
    });

    // Set up periodic sync when online
    _startPeriodicSync();
  }

  // Starts periodic sync
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    if (_isOnline) {
      _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
        if (_isOnline) {
          // Sync every 5 minutes when online
          // You can inject the context here or use a different approach
        }
      });
    }
  }
  
  // Manually checks connectivity status
  Future<bool> checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final wasOnline = _isOnline;
      _isOnline = connectivityResult != ConnectivityResult.none;
      
      if (wasOnline != _isOnline) {
        print('🔍 Connectivity changed: $_isOnline (${connectivityResult.name})');
      }
      
      return _isOnline;
    } catch (e) {
      print('🔍 Error checking connectivity: $e');
      _isOnline = false;
      return false;
    }
  }

  // Creates a group (online-first, offline-fallback)
  Future<void> createGroupOffline(String name, List<String> memberNames, BuildContext context, {String description = '', String currency = 'USD'}) async {
    print('🔍 SyncService: _isOnline = $_isOnline');
    
    // Double-check connectivity before making API call
    final isActuallyOnline = await checkConnectivity();
    print('🔍 Double-check connectivity: isActuallyOnline = $isActuallyOnline');
    
    if (isActuallyOnline) {
      // Test backend connectivity specifically
      final backendReachable = await ApiService.testConnectivity();
      print('🔍 Backend connectivity test: $backendReachable');
      
      // If connectivity test fails but we have internet, try API calls anyway
      // (connectivity test might fail due to DNS issues but API calls might work)
      if (backendReachable || isActuallyOnline) {
        // Try to create group via API first
        try {
          print('🌐 Attempting to create group via API: $name');
          print('📤 Request payload: name=$name, description=$description, currency=$currency, members=$memberNames');
          
          final apiResponse = await ApiService.createGroup(name, memberNames, description: description, currency: currency);
        
          // API succeeded - create group with backend ID
          final backendGroupId = apiResponse['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
          final linkToken = apiResponse['linkToken']?.toString();
          
          // Convert API users to Person objects
          final members = (apiResponse['users'] as List<dynamic>? ?? [])
              .map((user) => Person(
                    id: user['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    name: user['name'] ?? 'Unknown',
                  ))
              .toList();
          
          final group = Group(
            id: backendGroupId,
            name: name,
            description: apiResponse['description'] ?? '',
            currency: apiResponse['currency'] ?? 'USD',
            members: members,
            linkToken: linkToken,
            version: apiResponse['version'] ?? 1,
            createdAt: DateTime.parse(apiResponse['createdAt']),
            updatedAt: DateTime.parse(apiResponse['updatedAt']),
          );

          // Save to local storage with backend ID
          await LocalStorageService.saveGroup(group);
          
          // Update the provider
          if (context.mounted) {
            final provider = Provider.of<GroupProvider>(context, listen: false);
            provider.addGroup(group);
          }
          
          print('✅ Group created successfully via API with ID: $backendGroupId');
          return;
          
        } catch (e) {
          print('⚠️ API creation failed, falling back to offline mode: $e');
          print('🔍 Error details: ${e.toString()}');
          print('🔍 Error type: ${e.runtimeType}');
          if (e is Exception) {
            print('🔍 Exception message: ${e.toString()}');
          }
          // Fall through to offline creation
        }
      } else {
        print('⚠️ Backend not reachable, falling back to offline mode');
      }
    }
    
    // Offline creation (fallback or when offline)
    print('📱 Creating group offline: $name');
    final groupId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Create unique IDs for each member
    final members = memberNames.map((name) => 
      Person(id: '${DateTime.now().millisecondsSinceEpoch}_${name.hashCode}', name: name)
    ).toList();
    
    final group = Group(
      id: groupId,
      name: name,
      description: description,
      currency: currency,
      members: members,
    );

    // Save to local storage immediately
    await LocalStorageService.saveGroup(group);
    
    // Update the provider
    if (context.mounted) {
      final provider = Provider.of<GroupProvider>(context, listen: false);
      provider.addGroup(group);
    }

    // Add to pending operations for later sync
    await LocalStorageService.addPendingOperation('create_group', {
      'groupId': groupId,
      'name': name,
      'memberNames': memberNames,
    });

    print('📱 Group created offline with ID: $groupId (will sync when online)');
  }
  
  // Deletes a group (online-first, offline-fallback)
  Future<void> deleteGroupOffline(String groupId, BuildContext context, [GroupProvider? groupProvider]) async {
    print('🔍 SyncService: Deleting group $groupId, _isOnline = $_isOnline');
    
    // Double-check connectivity before making API call
    final isActuallyOnline = await checkConnectivity();
    print('🔍 Double-check connectivity: isActuallyOnline = $isActuallyOnline');
    
    if (isActuallyOnline) {
      // Test backend connectivity specifically
      final backendReachable = await ApiService.testConnectivity();
      print('🔍 Backend connectivity test: $backendReachable');
      
      // If connectivity test fails but we have internet, try API calls anyway
      // (connectivity test might fail due to DNS issues but API calls might work)
      if (backendReachable || isActuallyOnline) {
        // Try to delete group via API first
        try {
          print('🌐 Attempting to delete group via API: $groupId');
          
          final success = await ApiService.deleteGroup(groupId);
          
          if (success) {
            // API succeeded - remove from local storage and provider
            await LocalStorageService.deleteGroup(groupId);
            
            // Also remove user member mapping for this group
            await LocalStorageService.removeUserMemberMapping(groupId);
            
            if (context.mounted) {
              final provider = groupProvider ?? Provider.of<GroupProvider>(context, listen: false);
              provider.removeGroupFromMemory(groupId);
            }
            
            print('✅ Group deleted successfully via API: $groupId');
            return;
          }
          
        } catch (e) {
          print('⚠️ API deletion failed, falling back to offline mode: $e');
          print('🔍 Error details: ${e.toString()}');
          print('🔍 Error type: ${e.runtimeType}');
          if (e is Exception) {
            print('🔍 Exception message: ${e.toString()}');
          }
          // Fall through to offline deletion
        }
      } else {
        print('⚠️ Backend not reachable, falling back to offline mode');
      }
    }
    
    // Offline deletion (fallback or when offline)
    print('📱 Deleting group offline: $groupId');
    
    // Remove from local storage immediately
    await LocalStorageService.deleteGroup(groupId);
    
    // Also remove user member mapping for this group
    await LocalStorageService.removeUserMemberMapping(groupId);
    
    // Update the provider
    if (context.mounted) {
      final provider = groupProvider ?? Provider.of<GroupProvider>(context, listen: false);
      provider.removeGroupFromMemory(groupId);
    }

    // Add to pending operations for later sync
    await LocalStorageService.addPendingOperation('delete_group', {
      'groupId': groupId,
    });

    print('📱 Group deleted offline with ID: $groupId (will sync when online)');
  }
  
  // Joins a group (online-first, offline-fallback)
  Future<void> joinGroupOffline(String inviteLink, BuildContext context) async {
    // Always try to join group via API first, regardless of _isOnline status
    // (similar to createGroupOffline logic)
    try {
      print('🌐 Attempting to join group via API: $inviteLink');
      final apiResponse = await ApiService.joinGroup(inviteLink);
        
        // API succeeded - extract group details
        final actualGroupId = apiResponse['actualGroupId'];
        
        if (actualGroupId != null) {
          // Handle both direct response and nested response structures
          final groupData = apiResponse['groupDetails'] ?? apiResponse;
          
          // Convert API response to Group object
          // Backend returns 'users' field, not 'members'
          final members = (groupData['users'] as List<dynamic>? ?? [])
              .map((m) => Person(
                    id: m['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    name: m['name'] ?? 'Unknown',
                  ))
              .toList();
          
          print('🔍 Parsed ${members.length} members from join response');
          for (final member in members) {
            print('  - Member: ${member.name} (ID: ${member.id})');
          }
          
          // Extract expenses from group data (they should be included with withExpenses=true)
          List<Expense> expenses = [];
          try {
            if (groupData['expenses'] != null) {
              print('📋 Found ${(groupData['expenses'] as List).length} expenses in group data');
              
              expenses = (groupData['expenses'] as List).map((expenseData) {
                // Extract split information from paidFor field
                List<String> splitBetween = [];
                if (expenseData['paidFor'] != null && expenseData['paidFor']['repartition'] != null) {
                  final repartition = expenseData['paidFor']['repartition'] as List;
                  for (final item in repartition) {
                    final userId = item['userId'].toString();
                    // Find member by ID and add the ID to splitBetween (not the name)
                    final member = members.firstWhere(
                      (m) => m.id == userId,
                      orElse: () => members.first,
                    );
                    splitBetween.add(member.id); // Use ID, not name
                  }
                }
                
                // Extract paidBy information from API response
                String paidBy = members.first.id; // Default fallback
                if (expenseData['paidBy'] != null && expenseData['paidBy']['repartition'] != null) {
                  final repartition = expenseData['paidBy']['repartition'] as List;
                  if (repartition.isNotEmpty) {
                    final userId = repartition.first['userId'].toString();
                    // Find member by ID
                    final member = members.firstWhere(
                      (m) => m.id == userId,
                      orElse: () => members.first,
                    );
                    paidBy = member.id; // Use member ID
                  }
                }
                
                return Expense(
                  id: expenseData['id'].toString(),
                  name: expenseData['name'],
                  amount: expenseData['amount'].toDouble(),
                  currency: expenseData['currency'],
                  paidBy: paidBy,
                  splitBetween: splitBetween,
                  date: DateTime.parse(expenseData['date']),
                  groupId: actualGroupId,
                  category: expenseData['category'],
                  exchangeRate: expenseData['exchangeRate']?.toDouble(),
                  createdAt: DateTime.parse(expenseData['createdAt']),
                  updatedAt: expenseData['updatedAt'] != null ? DateTime.parse(expenseData['updatedAt']) : null,
                  version: expenseData['version'],
                  images: expenseData['images'] != null ? List<String>.from(expenseData['images']) : null,
                );
              }).toList();
              
              print('✅ Parsed ${expenses.length} expenses from group data');
            } else {
              print('📋 No expenses found in group data, using empty list');
            }
          } catch (e) {
            print('⚠️ Failed to parse expenses from group data, continuing with empty list: $e');
            // Continue with empty expenses list
          }
          final group = Group(
            id: actualGroupId,
            name: groupData['name'] ?? 'Unknown Group',
            description: groupData['description'] ?? '',
            currency: groupData['currency'] ?? 'USD',
            members: members,

            expenses: expenses,
            linkToken: groupData['linkToken'],
            version: groupData['version'] ?? 1,
            createdAt: DateTime.parse(groupData['createdAt']),
            updatedAt: DateTime.parse(groupData['updatedAt']),
          );
          
          // Save to local storage
          await LocalStorageService.saveGroup(group);
          
          // Update the provider
          if (context.mounted) {
            final provider = Provider.of<GroupProvider>(context, listen: false);
            provider.addGroup(group);
          }
          
          print('✅ Group joined successfully via API with ID: $actualGroupId');
          return;
        }
        
    } catch (e) {
      print('⚠️ API join failed: $e');
      
      // Show error message to user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to join group: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Adds an expense (offline-first)
  Future<void> addExpenseOffline(Expense expense, BuildContext context) async {
    // Save to local storage immediately
    await LocalStorageService.saveExpense(expense);
    
    // Update the provider
    if (context.mounted) {
      final provider = Provider.of<GroupProvider>(context, listen: false);
      provider.addExpense(expense);
    }

    // Add to pending operations for later sync
    await LocalStorageService.addPendingOperation('add_expense', {
      'expenseId': expense.id,
      'groupId': expense.groupId,
      'data': expense.toJson(),
    });

    // Try to sync immediately if online
    if (_isOnline) {
      _syncPendingOperations(context);
    }
  }

  // Updates an expense (online-first, offline-fallback)
  Future<void> updateExpenseOffline(Expense expense, BuildContext context, [GroupProvider? groupProvider]) async {
    print('🔍 SyncService: Updating expense ${expense.id}, _isOnline = $_isOnline');
    
    // Double-check connectivity before making API call
    final isActuallyOnline = await checkConnectivity();
    print('🔍 Double-check connectivity: isActuallyOnline = $isActuallyOnline');
    
    if (isActuallyOnline) {
      // Test backend connectivity specifically
      final backendReachable = await ApiService.testConnectivity();
      print('🔍 Backend connectivity test: $backendReachable');
      
      // If connectivity test fails but we have internet, try API calls anyway
      if (backendReachable || isActuallyOnline) {
        // Try to update expense via API first
        try {
          print('🌐 Attempting to update expense via API: ${expense.id}');
          
          // Get current group for member names
          final provider = groupProvider ?? Provider.of<GroupProvider>(context, listen: false);
          final currentGroup = provider.currentGroup;
          if (currentGroup == null) {
            throw Exception('No current group found');
          }
          
          await ApiService.updateExpense(
            expenseId: expense.id,
            groupId: expense.groupId,
            name: expense.name,
            amount: expense.amount,
            currency: expense.currency,
            paidByPersonId: expense.paidBy,
            splitBetweenPersonIds: expense.splitBetween,
            category: expense.category ?? 'OTHER',
            exchangeRate: expense.exchangeRate ?? 1.0,
            memberNames: currentGroup.members.map((m) => m.name).toList(),
            date: expense.date,
            customShares: expense.customShares,
            customPaidBy: expense.customPaidBy,
            images: expense.images,
          );
          
          // API succeeded - update local storage and provider
          await LocalStorageService.saveExpense(expense);
          
          if (context.mounted) {
            final provider = groupProvider ?? Provider.of<GroupProvider>(context, listen: false);
            provider.updateExpense(expense);
          }
          
          print('✅ Expense updated successfully via API: ${expense.id}');
          return;
          
        } catch (e) {
          print('⚠️ API update failed, falling back to offline mode: $e');
          print('🔍 Error details: ${e.toString()}');
          print('🔍 Error type: ${e.runtimeType}');
          if (e is Exception) {
            print('🔍 Exception message: ${e.toString()}');
          }
          // Fall through to offline update
        }
      } else {
        print('⚠️ Backend not reachable, falling back to offline mode');
      }
    }
    
    // Offline update (fallback or when offline)
    print('📱 Updating expense offline: ${expense.id}');
    
    // Update local storage immediately
    await LocalStorageService.saveExpense(expense);
    
    // Update the provider
    if (context.mounted) {
      final provider = groupProvider ?? Provider.of<GroupProvider>(context, listen: false);
      provider.updateExpense(expense);
    }

    // Add to pending operations for later sync
    await LocalStorageService.addPendingOperation('update_expense', {
      'expenseId': expense.id,
      'groupId': expense.groupId,
      'data': expense.toJson(),
    });

    print('📱 Expense updated offline with ID: ${expense.id} (will sync when online)');
  }

  // Deletes an expense (online-first, offline-fallback)
  Future<void> deleteExpenseOffline(String expenseId, BuildContext context, [GroupProvider? groupProvider]) async {
    print('🔍 SyncService: Deleting expense $expenseId, _isOnline = $_isOnline');
    
    // Double-check connectivity before making API call
    final isActuallyOnline = await checkConnectivity();
    print('🔍 Double-check connectivity: isActuallyOnline = $isActuallyOnline');
    
    if (isActuallyOnline) {
      // Test backend connectivity specifically
      final backendReachable = await ApiService.testConnectivity();
      print('🔍 Backend connectivity test: $backendReachable');
      
      // If connectivity test fails but we have internet, try API calls anyway
      if (backendReachable || isActuallyOnline) {
        // Try to delete expense via API first
        try {
          print('🌐 Attempting to delete expense via API: $expenseId');
          
          final success = await ApiService.deleteExpense(expenseId);
          
          if (success) {
            // API succeeded - remove from local storage and provider
            await LocalStorageService.deleteExpense(expenseId);
            
            if (context.mounted) {
              final provider = groupProvider ?? Provider.of<GroupProvider>(context, listen: false);
              provider.removeExpense(expenseId);
            }
            
            print('✅ Expense deleted successfully via API: $expenseId');
            return;
          }
          
        } catch (e) {
          print('⚠️ API deletion failed, falling back to offline mode: $e');
          print('🔍 Error details: ${e.toString()}');
          print('🔍 Error type: ${e.runtimeType}');
          if (e is Exception) {
            print('🔍 Exception message: ${e.toString()}');
          }
          // Fall through to offline deletion
        }
      } else {
        print('⚠️ Backend not reachable, falling back to offline mode');
      }
    }
    
    // Offline deletion (fallback or when offline)
    print('📱 Deleting expense offline: $expenseId');
    
    // Remove from local storage immediately
    await LocalStorageService.deleteExpense(expenseId);
    
    // Update the provider
    if (context.mounted) {
      final provider = groupProvider ?? Provider.of<GroupProvider>(context, listen: false);
      provider.removeExpense(expenseId);
    }

    // Add to pending operations for later sync
    await LocalStorageService.addPendingOperation('delete_expense', {
      'expenseId': expenseId,
    });

    print('📱 Expense deleted offline with ID: $expenseId (will sync when online)');
  }
  


  // Syncs pending operations with backend
  Future<void> _syncPendingOperations(BuildContext context) async {
    if (!_isOnline) return;

    final pendingOperations = LocalStorageService.getPendingOperations();
    
    for (final operation in pendingOperations) {
      try {
        switch (operation['operation']) {
          case 'create_group':
            await _syncCreateGroup(operation['data']);
            break;
          case 'add_expense':
            await _syncAddExpense(operation['data']);
            break;
        }
        
        // Remove successful operation
        await LocalStorageService.removePendingOperation(operation['id']);
      } catch (e) {
        print('Failed to sync operation: $e');
        // Keep failed operations for retry
      }
    }
  }

  // Syncs create group operation
  Future<void> _syncCreateGroup(Map<String, dynamic> data) async {
    try {
      await ApiService.createGroup(data['name'], data['memberNames']);
    } catch (e) {
      throw Exception('Failed to sync group creation: $e');
    }
  }

  // Syncs add expense operation
  Future<void> _syncAddExpense(Map<String, dynamic> data) async {
    try {
      // You'll need to implement this in ApiService
      // await ApiService.addExpense(data['data']);
      print('Expense sync not yet implemented');
    } catch (e) {
      throw Exception('Failed to sync expense: $e');
    }
  }

  // Checks if online.
  bool get isOnline => _isOnline;

  // Manual sync trigger
  Future<void> manualSync(BuildContext context) async {
    if (_isOnline) {
      await _syncPendingOperations(context);
    }
  }

  // Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
  }
}
