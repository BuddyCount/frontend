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
  final String? description;
  
  @HiveField(3)
  final String currency;
  
  @HiveField(4)
  final List<Person> members;
  
  @HiveField(5)
  final List<Expense> expenses;
  
  @HiveField(6)
  final String? linkToken;
  
  @HiveField(7)
  final int version;
  
  @HiveField(8)
  final DateTime createdAt;
  
  @HiveField(9)
  final DateTime updatedAt;

  Group({
    required this.id,
    required this.name,
    this.description,
    required this.currency,
    required this.members,
    List<Expense>? expenses,
    this.linkToken,
    this.version = 1,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    expenses = expenses ?? [],
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? currency,
    List<Person>? members,
    List<Expense>? expenses,
    String? linkToken,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      currency: currency ?? this.currency,
      members: members ?? this.members,
      expenses: expenses ?? this.expenses,
      linkToken: linkToken ?? this.linkToken,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'currency': currency,
      'members': members.map((m) => m.toJson()).toList(),
      'expenses': expenses.map((e) => e.toJson()).toList(),
      'linkToken': linkToken,
      'version': version,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      currency: json['currency'] ?? 'USD',
      members: (json['members'] as List)
          .map((m) => Person.fromJson(m))
          .toList(),
      expenses: (json['expenses'] as List?)
          ?.map((e) => Expense.fromJson(e))
          .toList() ?? [],
      linkToken: json['linkToken'],
      version: json['version'] ?? 1,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
} 