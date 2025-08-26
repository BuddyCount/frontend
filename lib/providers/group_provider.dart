import 'package:flutter/foundation.dart';
import '../models/group.dart';
import '../models/expense.dart';
import '../models/person.dart';

class GroupProvider with ChangeNotifier {
  List<Group> _groups = [];
  Group? _currentGroup;

  List<Group> get groups => _groups;
  Group? get currentGroup => _currentGroup;

  // Initialize with sample data
  GroupProvider() {
    _initializeSampleData();
  }

  void _initializeSampleData() {
    final person1 = Person(id: '1', name: 'Alice');
    final person2 = Person(id: '2', name: 'Bob');
    final person3 = Person(id: '3', name: 'Charlie');

    final sampleGroup = Group(
      id: '1',
      name: 'Trip to Paris',
      members: [person1, person2, person3],
      currency: 'EUR',
    );

    _groups.add(sampleGroup);
    _currentGroup = sampleGroup;
    notifyListeners();
  }

  void setCurrentGroup(Group group) {
    _currentGroup = group;
    notifyListeners();
  }

  void addGroup(Group group) {
    _groups.add(group);
    notifyListeners();
  }

  void removeGroup(String groupId) {
    _groups.removeWhere((group) => group.id == groupId);
    if (_currentGroup?.id == groupId) {
      _currentGroup = _groups.isNotEmpty ? _groups.first : null;
    }
    notifyListeners();
  }

  void addExpense(Expense expense) {
    if (_currentGroup != null) {
      _currentGroup!.addExpense(expense);
      notifyListeners();
    }
  }

  void removeExpense(String expenseId) {
    if (_currentGroup != null) {
      _currentGroup!.removeExpense(expenseId);
      notifyListeners();
    }
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