class Product{
  final String id;
  final String name;
  final double import_price;
  final double selling_pricw;
  final double quantity;
  final String category;

  const Product({
    required this.id,
    required this.name,
    required this.import_price,
    required this.selling_pricw,
    required this.quantity,
    required this.category
  });
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      import_price: json['import_price'],
      selling_pricw: json['selling_price'],
      quantity: json['quantity'],
      category: json['category']
    );
  }
}