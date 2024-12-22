import 'dart:collection';

import 'product.dart';

class Inventory {
  static const int initiated = 0;
  static const int active = 1;

  final String id;
  String date = '';
  int state = Inventory.initiated;
  late HashMap<String, Product> counts;

  Inventory({
    required this.id,
    required this.date,
    required this.state,
  });

  bool isActive() {
    return state == active;
  }

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      id: json['_id'],
      date: json['date'],
      state: json['state'],
    );
  }
}
