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

  Expense({
    required this.id,
    required this.name,
    required this.amount,
    required this.currency,
    required this.paidBy,
    required this.splitBetween,
    required this.date,
    required this.groupId,
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
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      name: json['name'],
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'],
      paidBy: json['paidBy'],
      splitBetween: List<String>.from(json['splitBetween']),
      date: DateTime.parse(json['date']),
      groupId: json['groupId'] ?? '',
    );
  }
} 