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

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

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

  // Start periodic sync
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
  
  // Manually check connectivity status
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

  // Create group (online-first, offline-fallback)
  Future<void> createGroupOffline(String name, List<String> memberNames, BuildContext context, {String description = '', String currency = 'USD'}) async {
    print('🔍 SyncService: _isOnline = $_isOnline');
    
    // Double-check connectivity before making API call
    final isActuallyOnline = await checkConnectivity();
    print('🔍 Double-check connectivity: isActuallyOnline = $isActuallyOnline');
    
    if (isActuallyOnline) {
      // Test backend connectivity specifically
      final backendReachable = await ApiService.testConnectivity();
      print('🔍 Backend connectivity test: $backendReachable');
      
      if (backendReachable) {
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
  
  // Delete group (online-first, offline-fallback)
  Future<void> deleteGroupOffline(String groupId, BuildContext context) async {
    print('🔍 SyncService: Deleting group $groupId, _isOnline = $_isOnline');
    
    // Double-check connectivity before making API call
    final isActuallyOnline = await checkConnectivity();
    print('🔍 Double-check connectivity: isActuallyOnline = $isActuallyOnline');
    
    if (isActuallyOnline) {
      // Test backend connectivity specifically
      final backendReachable = await ApiService.testConnectivity();
      print('🔍 Backend connectivity test: $backendReachable');
      
      if (backendReachable) {
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
              final provider = Provider.of<GroupProvider>(context, listen: false);
              provider.removeGroup(groupId);
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
      final provider = Provider.of<GroupProvider>(context, listen: false);
      provider.removeGroup(groupId);
    }

    // Add to pending operations for later sync
    await LocalStorageService.addPendingOperation('delete_group', {
      'groupId': groupId,
    });

    print('📱 Group deleted offline with ID: $groupId (will sync when online)');
  }
  
  // Join group (online-first, offline-fallback)
  Future<void> joinGroupOffline(String inviteLink, BuildContext context) async {
    if (_isOnline) {
      // Try to join group via API first
      try {
        print('🌐 Attempting to join group via API: $inviteLink');
        final apiResponse = await ApiService.joinGroup(inviteLink);
        
        // API succeeded - extract group details
        final groupDetails = apiResponse['groupDetails'];
        final actualGroupId = apiResponse['actualGroupId'];
        
        if (groupDetails != null && actualGroupId != null) {
          // Convert API response to Group object
          final members = (groupDetails['members'] as List<dynamic>? ?? [])
              .map((m) => Person(
                    id: m['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    name: m['name'] ?? 'Unknown',
                  ))
              .toList();
          
          final group = Group(
            id: actualGroupId,
            name: groupDetails['name'] ?? 'Unknown Group',
            description: groupDetails['description'] ?? '',
            currency: groupDetails['currency'] ?? 'USD',
            members: members,
            linkToken: groupDetails['linkToken'],
            version: groupDetails['version'] ?? 1,
            createdAt: DateTime.parse(groupDetails['createdAt']),
            updatedAt: DateTime.parse(groupDetails['updatedAt']),
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
        print('⚠️ API join failed, falling back to offline mode: $e');
        // Fall through to offline handling
      }
    }
    
    // Offline handling (when offline or API fails)
    print('📱 Cannot join group while offline: $inviteLink');
    
    // Show offline message to user
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📱 Cannot join groups while offline. Please try again when connected.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  // Add expense (offline-first)
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
  


  // Sync pending operations with backend
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

  // Sync create group operation
  Future<void> _syncCreateGroup(Map<String, dynamic> data) async {
    try {
      await ApiService.createGroup(data['name'], data['memberNames']);
    } catch (e) {
      throw Exception('Failed to sync group creation: $e');
    }
  }

  // Sync add expense operation
  Future<void> _syncAddExpense(Map<String, dynamic> data) async {
    try {
      // You'll need to implement this in ApiService
      // await ApiService.addExpense(data['data']);
      print('Expense sync not yet implemented');
    } catch (e) {
      throw Exception('Failed to sync expense: $e');
    }
  }

  // Check if online.
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
