import 'dart:collection';

import 'product.dart';

class Inventory {
  static const int INITIATED = 0;
  static const int ACTIVE = 1;
  static const int CLOSED = 2;

  final String id;
  String date = '';
  int state = Inventory.INITIATED;
  HashMap<String, Product> counts = HashMap();

  Inventory({required this.id, required this.date, required this.state});

  bool isActive() {
    return state == ACTIVE;
  }

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      id: json['_id'],
      date: json['date'],
      state: json['state'],
    );
  }
}
