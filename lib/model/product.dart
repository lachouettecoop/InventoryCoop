class Product {
  final String id;
  final String name;
  final String barcode;

  Product({
    required this.id,
    required this.name,
    required this.barcode,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'],
      name: json['name'],
      barcode: json['barcode'],
    );
  }
}
