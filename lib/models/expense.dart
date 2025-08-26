class Expense {
  final String id;
  final String name;
  final double amount;
  final String currency;
  final String paidBy;
  final DateTime date;
  final List<String> splitBetween;

  Expense({
    required this.id,
    required this.name,
    required this.amount,
    required this.currency,
    required this.paidBy,
    required this.date,
    required this.splitBetween,
  });

  Expense copyWith({
    String? id,
    String? name,
    double? amount,
    String? currency,
    String? paidBy,
    DateTime? date,
    List<String>? splitBetween,
  }) {
    return Expense(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paidBy: paidBy ?? this.paidBy,
      date: date ?? this.date,
      splitBetween: splitBetween ?? this.splitBetween,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'currency': currency,
      'paidBy': paidBy,
      'date': date.toIso8601String(),
      'splitBetween': splitBetween,
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      name: json['name'],
      amount: json['amount'].toDouble(),
      currency: json['currency'],
      paidBy: json['paidBy'],
      date: DateTime.parse(json['date']),
      splitBetween: List<String>.from(json['splitBetween']),
    );
  }
} 