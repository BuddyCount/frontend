/**
 * File: person.dart
 * Description: Model for people in a group, to use with Hive for local database storage
 * Author: Sergey Komarov
 * Date: 2025-09-05
 */

import 'package:hive/hive.dart';

part 'person.g.dart';

@HiveType(typeId: 1)
class Person extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;

  Person({
    required this.id,
    required this.name,
  });

  Person copyWith({
    String? id,
    String? name,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'],
      name: json['name'],
    );
  }
} 