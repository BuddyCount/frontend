import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 2)
class Expense extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final double amount;
  
  @HiveField(3)
  final String currency;
  
  @HiveField(4)
  final String paidBy;
  
  @HiveField(5)
  final List<String> splitBetween;
  
  @HiveField(6)
  final DateTime date;
  
  @HiveField(7)
  final String groupId;
  
  @HiveField(8)
  final String? category;
  
  @HiveField(9)
  final double? exchangeRate;
  
  @HiveField(10)
  final DateTime? createdAt;
  
  @HiveField(11)
  final DateTime? updatedAt;
  
  @HiveField(12)
  final int? version;

  Expense({
    required this.id,
    required this.name,
    required this.amount,
    required this.currency,
    required this.paidBy,
    required this.splitBetween,
    required this.date,
    required this.groupId,
    this.category,
    this.exchangeRate,
    this.createdAt,
    this.updatedAt,
    this.version,
  });

  Expense copyWith({
    String? id,
    String? name,
    double? amount,
    String? currency,
    String? paidBy,
    List<String>? splitBetween,
    DateTime? date,
    String? groupId,
    String? category,
    double? exchangeRate,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
  }) {
    return Expense(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paidBy: paidBy ?? this.paidBy,
      splitBetween: splitBetween ?? this.splitBetween,
      date: date ?? this.date,
      groupId: groupId ?? this.groupId,
      category: category ?? this.category,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'currency': currency,
      'paidBy': paidBy,
      'splitBetween': splitBetween,
      'date': date.toIso8601String(),
      'groupId': groupId,
      'category': category,
      'exchangeRate': exchangeRate,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'version': version,
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'USD',
      paidBy: json['paidBy'] ?? '',
      splitBetween: List<String>.from(json['splitBetween'] ?? []),
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      groupId: json['groupId'] ?? '',
      category: json['category'],
      exchangeRate: json['exchange_rate'] != null ? (json['exchange_rate'] as num).toDouble() : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      version: json['version'],
    );
  }
} 