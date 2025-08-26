import 'package:hive_flutter/hive_flutter.dart';
import '../models/group.dart';
import '../models/expense.dart';
import '../models/person.dart';

class LocalStorageService {
  static const String _groupsBoxName = 'groups';
  static const String _expensesBoxName = 'expenses';
  static const String _pendingOperationsBoxName = 'pending_operations';
  
  static late Box<Group> _groupsBox;
  static late Box<Expense> _expensesBox;
  static late Box<Map> _pendingOperationsBox;
  
  static Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Register adapters
    Hive.registerAdapter(GroupAdapter());
    Hive.registerAdapter(PersonAdapter());
    Hive.registerAdapter(ExpenseAdapter());
    
    // Open boxes
    _groupsBox = await Hive.openBox<Group>(_groupsBoxName);
    _expensesBox = await Hive.openBox<Expense>(_expensesBoxName);
    _pendingOperationsBox = await Hive.openBox<Map>(_pendingOperationsBoxName);
  }
  
  // Groups
  static List<Group> getAllGroups() {
    final groups = _groupsBox.values.toList();
    
    // For each group, load its associated expenses
    for (final group in groups) {
      final expenses = getExpensesForGroup(group.id);
      // Update the group with its expenses
      final updatedGroup = group.copyWith(expenses: expenses);
      // Update the group in memory (this doesn't save to storage, just updates the list)
      final index = groups.indexOf(group);
      if (index != -1) {
        groups[index] = updatedGroup;
      }
    }
    
    return groups;
  }
  
  static Group? getGroup(String id) {
    final group = _groupsBox.get(id);
    if (group != null) {
      // Load associated expenses for this group
      final expenses = getExpensesForGroup(id);
      return group.copyWith(expenses: expenses);
    }
    return null;
  }
  
  static Future<void> saveGroup(Group group) async {
    await _groupsBox.put(group.id, group);
    
    // Also save all expenses associated with this group
    for (final expense in group.expenses) {
      await saveExpense(expense);
    }
  }
  
  static Future<void> deleteGroup(String id) async {
    // First delete all expenses associated with this group
    final expenses = getExpensesForGroup(id);
    for (final expense in expenses) {
      await deleteExpense(expense.id);
    }
    
    // Then delete the group
    await _groupsBox.delete(id);
  }
  
  // Expenses
  static List<Expense> getExpensesForGroup(String groupId) {
    return _expensesBox.values
        .where((expense) => expense.groupId == groupId)
        .toList();
  }
  
  static Future<void> saveExpense(Expense expense) async {
    await _expensesBox.put(expense.id, expense);
  }
  
  static Future<void> deleteExpense(String id) async {
    await _expensesBox.delete(id);
  }
  
  // Pending Operations (for offline sync)
  static List<Map> getPendingOperations() {
    return _pendingOperationsBox.values.toList();
  }
  
  static Future<void> addPendingOperation(String operation, Map data) async {
    final operationData = {
      'operation': operation,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
    };
    await _pendingOperationsBox.put(operationData['id'], operationData);
  }
  
  static Future<void> removePendingOperation(String id) async {
    await _pendingOperationsBox.delete(id);
  }
  
  static Future<void> clearAllData() async {
    await _groupsBox.clear();
    await _expensesBox.clear();
    await _pendingOperationsBox.clear();
  }
  
  static Future<void> close() async {
    await _groupsBox.close();
    await _expensesBox.close();
    await _pendingOperationsBox.close();
  }
}
