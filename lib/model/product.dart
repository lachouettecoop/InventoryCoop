class Product {
  final String id;
  final String name;
  final String barcode;

  Product({this.id, this.name, this.barcode});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'],
      name: json['name'],
      barcode: json['barcode'],
    );
  }
}