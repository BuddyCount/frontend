import 'package:hive/hive.dart';
import 'person.dart';
import 'expense.dart';

part 'group.g.dart';

@HiveType(typeId: 0)
class Group extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final List<Person> members;
  
  @HiveField(3)
  final List<Expense> expenses;
  
  @HiveField(4)
  final DateTime createdAt;
  
  @HiveField(5)
  final DateTime updatedAt;

  Group({
    required this.id,
    required this.name,
    required this.members,
    List<Expense>? expenses,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    expenses = expenses ?? [],
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  Group copyWith({
    String? id,
    String? name,
    List<Person>? members,
    List<Expense>? expenses,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      members: members ?? this.members,
      expenses: expenses ?? this.expenses,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'members': members.map((m) => m.toJson()).toList(),
      'expenses': expenses.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
      members: (json['members'] as List)
          .map((m) => Person.fromJson(m))
          .toList(),
      expenses: (json['expenses'] as List?)
          ?.map((e) => Expense.fromJson(e))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
} 