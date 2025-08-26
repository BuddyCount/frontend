class Person {
  final String id;
  final String name;
  double balance;

  Person({
    required this.id,
    required this.name,
    this.balance = 0.0,
  });

  Person copyWith({
    String? id,
    String? name,
    double? balance,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
    };
  }

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'],
      name: json['name'],
      balance: json['balance'].toDouble(),
    );
  }
} 