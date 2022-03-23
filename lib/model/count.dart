import 'package:intl/intl.dart';

class Count {
  final String counter;
  final String zone;
  final String product;
  final String qty;

  Count(
      {required this.counter,
      required this.zone,
      required this.product,
      required this.qty});

  factory Count.fromJson(Map<String, dynamic> json) {
    return Count(
      counter: json['counter'],
      zone: json['zone'],
      product: json['product'],
      qty: NumberFormat('####.##').format(json['qty']),
    );
  }
}
