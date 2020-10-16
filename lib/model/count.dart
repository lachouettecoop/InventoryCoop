class Count {
  final String counter;
  final String zone;
  final String product;
  final String qty;

  Count({this.counter, this.zone, this.product, this.qty});

  factory Count.fromJson(Map<String, dynamic> json) {
    return Count(
      counter: json['counter'],
      zone: json['zone'],
      product: json['product'],
      qty: json['qty'].toString(),
    );
  }
}