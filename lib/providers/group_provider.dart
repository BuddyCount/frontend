import 'package:flutter/foundation.dart';
import '../models/group.dart';
import '../models/expense.dart';
import '../models/person.dart';
import '../services/local_storage_service.dart';


class GroupProvider with ChangeNotifier {
  List<Group> _groups = [];
  Group? _currentGroup;
  bool _isInitialized = false;
  
  // Map to store which member the current user is in each group
  // Key: groupId, Value: personId
  Map<String, String> _userMemberInGroups = {};

  List<Group> get groups => _groups;
  Group? get currentGroup => _currentGroup;
  bool get isInitialized => _isInitialized;
  
  // Get the current user's member ID for a specific group
  String? getUserMemberId(String groupId) => _userMemberInGroups[groupId];
  
  // Get the current user's Person object for a specific group
  Person? getUserMember(String groupId) {
    final memberId = _userMemberInGroups[groupId];
    if (memberId == null) return null;
    
    try {
      final group = _groups.firstWhere((g) => g.id == groupId);
      return group.members.firstWhere((p) => p.id == memberId);
    } catch (e) {
      return null;
    }
  }
  
  // Set which member the current user is in a specific group
  Future<void> setUserMember(String groupId, String personId) async {
    _userMemberInGroups[groupId] = personId;
    
    // Save to local storage for persistence
    try {
      await LocalStorageService.saveUserMemberMapping(groupId, personId);
      print('Saved user member mapping: Group $groupId -> Person $personId');
    } catch (e) {
      print('Error saving user member mapping: $e');
    }
    
    notifyListeners();
  }
  
  // Get the current user's personal balance for a specific group
  double? getUserPersonalBalance(String groupId) {
    final userMember = getUserMember(groupId);
    if (userMember == null) return null;
    
    try {
      final group = _groups.firstWhere((g) => g.id == groupId);
      final balances = calculateBalances(group);
      return balances[userMember.id];
    } catch (e) {
      return null;
    }
  }
  
  // Calculate balances for a group (moved from GroupDetailScreen)
  Map<String, double> calculateBalances(Group group) {
    final balances = <String, double>{};
    
    // Initialize all balances to 0
    for (final person in group.members) {
      balances[person.id] = 0.0;
    }
    
    // Calculate balances based on expenses
    for (final expense in group.expenses) {
      // Convert expense amount to group currency if different
      double expenseAmountInGroupCurrency = expense.amount;
      
      if (expense.currency != group.currency && expense.exchangeRate != null) {
        // Convert to group currency using exchange rate
        expenseAmountInGroupCurrency = expense.amount * expense.exchangeRate!;
        print('💰 Converting ${expense.amount} ${expense.currency} to ${expenseAmountInGroupCurrency} ${group.currency} (rate: ${expense.exchangeRate})');
      } else if (expense.currency != group.currency && expense.exchangeRate == null) {
        // No exchange rate provided, use 1:1 (this might not be accurate)
        print('⚠️ No exchange rate for ${expense.amount} ${expense.currency} to ${group.currency}, using 1:1');
      }
      
      final payer = group.members.firstWhere((p) => p.id == expense.paidBy);
      
      // Handle multiple payers or single payer
      if (expense.customPaidBy != null && expense.customPaidBy!.isNotEmpty) {
        // Multiple payers with custom amounts
        for (final entry in expense.customPaidBy!.entries) {
          final payerId = entry.key;
          final paidAmount = entry.value;
          balances[payerId] = (balances[payerId] ?? 0.0) + paidAmount;
        }
      } else {
        // Single payer gets the full amount (in group currency)
        balances[payer.id] = (balances[payer.id] ?? 0.0) + expenseAmountInGroupCurrency;
      }
      
      // Calculate how much each person owes based on custom shares or equal splitting
      if (expense.customShares != null && expense.customShares!.isNotEmpty) {
        // Use custom shares for proportional splitting
        final totalShares = expense.customShares!.values.reduce((a, b) => a + b);
        
        for (final personId in expense.splitBetween) {
          final personShares = expense.customShares![personId] ?? 1.0;
          final personAmount = (personShares / totalShares) * expenseAmountInGroupCurrency;
          balances[personId] = (balances[personId] ?? 0.0) - personAmount;
        }
      } else {
        // Equal splitting (original behavior)
        final splitAmount = expenseAmountInGroupCurrency / expense.splitBetween.length;
        
        for (final personId in expense.splitBetween) {
          balances[personId] = (balances[personId] ?? 0.0) - splitAmount;
        }
      }
    }
    
    return balances;
  }
  
  // Get groups for a specific person
  List<Group> getGroupsForPerson(String personId) {
    return _groups.where((group) => 
      group.members.any((person) => person.id == personId)
    ).toList();
  }
  
  // Get all unique people across all groups
  List<Person> get allPeople {
    final peopleMap = <String, Person>{};
    for (final group in _groups) {
      for (final person in group.members) {
        peopleMap[person.id] = person;
      }
    }
    return peopleMap.values.toList();
  }

  // Initialize with local storage data
  GroupProvider() {
    // Initialize immediately with empty state, then load from storage
    _isInitialized = false;
    _initializeFromStorage();
  }

  Future<void> _initializeFromStorage() async {
    try {
      // Add a small delay to ensure Hive is fully initialized
      await Future.delayed(const Duration(milliseconds: 100));
      
      print('Loading groups from storage...');
      final storedGroups = LocalStorageService.getAllGroups();
      print('Found ${storedGroups.length} groups in storage');
      
      _groups = storedGroups;
      
      // Load user member mappings from storage
      print('Loading user member mappings from storage...');
      final storedUserMembers = LocalStorageService.getAllUserMemberMappings();
      _userMemberInGroups = storedUserMembers;
      print('Found ${storedUserMembers.length} user member mappings in storage');
      
      if (_groups.isNotEmpty) {
        _currentGroup = _groups.first;
        print('Set current group: ${_currentGroup!.name}');
      } else {
        print('No groups found in storage');
      }
      
      _isInitialized = true;
      print('Initialization complete. Total groups: ${_groups.length}, user members: ${_userMemberInGroups.length}');
      notifyListeners();
    } catch (e) {
      print('Error loading from storage: $e');
      // Start with empty state on error
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> setCurrentGroup(Group group) async {
    _currentGroup = group;
    
    // Save the current group to storage to persist the selection
    try {
      await LocalStorageService.saveGroup(group);
      print('Successfully saved current group "${group.name}" to storage');
    } catch (e) {
      print('Error saving current group to storage: $e');
    }
    
    notifyListeners();
  }

  // Manual refresh from storage (useful for debugging and ensuring data persistence)
  Future<void> refreshFromStorage() async {
    try {
      print('Manually refreshing from storage...');
      final storedGroups = LocalStorageService.getAllGroups();
      print('Found ${storedGroups.length} groups in storage during refresh');
      
      _groups = storedGroups;
      
      if (_groups.isNotEmpty && _currentGroup == null) {
        _currentGroup = _groups.first;
        print('Set current group during refresh: ${_currentGroup!.name}');
      }
      
      notifyListeners();
      print('Refresh complete. Total groups: ${_groups.length}');
    } catch (e) {
      print('Error refreshing from storage: $e');
    }
  }

  Future<void> addGroup(Group group) async {
    // Check if group already exists
    final existingIndex = _groups.indexWhere((g) => g.id == group.id);
    if (existingIndex != -1) {
      // Update existing group
      _groups[existingIndex] = group;
    } else {
      // Add new group
      _groups.add(group);
    }
    
    // Set as current group if it's the first one
    if (_currentGroup == null) {
      _currentGroup = group;
    }
    
    // Save the group to storage (this will also save its expenses)
    try {
      await LocalStorageService.saveGroup(group);
      print('Successfully saved group "${group.name}" to storage');
    } catch (e) {
      print('Error saving group to storage: $e');
    }
    
    notifyListeners();
  }

  Future<void> removeGroup(String groupId) async {
    _groups.removeWhere((group) => group.id == groupId);
    if (_currentGroup?.id == groupId) {
      _currentGroup = _groups.isNotEmpty ? _groups.first : null;
    }
    
    // Remove the group from storage (this will also remove its expenses)
    try {
      await LocalStorageService.deleteGroup(groupId);
      print('Successfully removed group $groupId from storage');
    } catch (e) {
      print('Error removing group from storage: $e');
    }
    
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    // Find the correct group based on the expense's groupId
    final groupIndex = _groups.indexWhere((g) => g.id == expense.groupId);
    if (groupIndex != -1) {
      // Add expense to the correct group
      final group = _groups[groupIndex];
      final updatedExpenses = List<Expense>.from(group.expenses)..add(expense);
      final updatedGroup = group.copyWith(expenses: updatedExpenses);
      
      // Update the groups list
      _groups[groupIndex] = updatedGroup;
      
      // Update current group if it's the same group
      if (_currentGroup?.id == expense.groupId) {
        _currentGroup = updatedGroup;
      }
      
      // Save both the expense and the updated group to storage
      try {
        await LocalStorageService.saveExpense(expense);
        await LocalStorageService.saveGroup(updatedGroup);
        print('Successfully saved expense "${expense.name}" to storage');
      } catch (e) {
        print('Error saving expense to storage: $e');
      }
      
      notifyListeners();
    } else {
      print('Warning: Could not find group with id ${expense.groupId} for expense ${expense.name}');
    }
  }

  Future<void> removeExpense(String expenseId) async {
    // Find which group contains this expense
    for (int i = 0; i < _groups.length; i++) {
      final group = _groups[i];
      final expenseIndex = group.expenses.indexWhere((e) => e.id == expenseId);
      
      if (expenseIndex != -1) {
        // Remove expense from this group
        final updatedExpenses = List<Expense>.from(group.expenses)..removeAt(expenseIndex);
        final updatedGroup = group.copyWith(expenses: updatedExpenses);
        
        // Update the groups list
        _groups[i] = updatedGroup;
        
        // Update current group if it's the same group
        if (_currentGroup?.id == group.id) {
          _currentGroup = updatedGroup;
        }
        
        // Save the updated group to storage and delete the expense
        try {
          await LocalStorageService.deleteExpense(expenseId);
          await LocalStorageService.saveGroup(updatedGroup);
          print('Successfully removed expense $expenseId from storage');
        } catch (e) {
          print('Error removing expense from storage: $e');
        }
        
        notifyListeners();
        return;
      }
    }
    
    print('Warning: Could not find expense with id $expenseId to remove');
  }

  void addPerson(Person person) {
    if (_currentGroup != null) {
      _currentGroup!.members.add(person);
      notifyListeners();
    }
  }

  void removePerson(String personId) {
    if (_currentGroup != null) {
      _currentGroup!.members.removeWhere((person) => person.id == personId);
      notifyListeners();
    }
  }
} 