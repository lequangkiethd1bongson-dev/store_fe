class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.rating,
    required this.category,
    required this.imageUrl,
    this.oldPrice,
    this.importPrice,
    this.barcode,
    this.brand,
    this.packageSize,
    this.description,
    this.stock = 24,
  });

  final String id;
  final String name;

  /// giá bán hiện tại (tương ứng `selling_price` trong database).
  final int price;
  final int? oldPrice;

  /// giá nhập (tương ứng `import_price`), khách hàng không cần.
  final int? importPrice;
  final String? barcode;
  final double rating;
  final String category;
  final String imageUrl;
  final String? brand;
  final String? packageSize;
  final String? description;

  /// số lượng còn bán được (tương ứng `quantity`).
  final int stock;

  /// tính phần trăm giảm giá nếu giá cũ lớn hơn giá hiện tại.
  int? get discountPercent {
    final previousPrice = oldPrice;
    if (previousPrice == null || previousPrice <= price) return null;
    return ((previousPrice - price) / previousPrice * 100).round();
  }

  /// chuyển một object json từ backend thành [Product].
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: _pick(json, ['id', 'productId', 'product_id'])?.toString() ?? '',
      name:
          _pick(json, ['name', 'productName', 'product_name'])?.toString() ??
          '',
      price:
          _toInt(_pick(json, ['price', 'sellingPrice', 'selling_price'])) ?? 0,
      oldPrice: _toInt(_pick(json, ['oldPrice', 'old_price'])),
      importPrice: _toInt(_pick(json, ['importPrice', 'import_price'])),
      barcode: _pick(json, ['barcode'])?.toString(),
      rating: _toDouble(json['rating']) ?? 0,
      category: _readCategory(json['category']),
      imageUrl:
          _pick(json, ['imageUrl', 'image_url', 'image'])?.toString() ?? '',
      brand: json['brand']?.toString(),
      packageSize: _pick(json, ['packageSize', 'package_size'])?.toString(),
      description: json['description']?.toString(),
      stock:
          _toInt(
            _pick(json, [
              'storeStockQuantity',
              'store_stock_quantity',
              'stock',
              'quantity',
              'warehouseQuantity',
              'warehouse_quantity',
            ]),
          ) ??
          0,
    );
  }

  /// chuyển [Product] thành json, dùng khi gửi dữ liệu lên backend.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'oldPrice': oldPrice,
    'importPrice': importPrice,
    'barcode': barcode,
    'rating': rating,
    'category': category,
    'imageUrl': imageUrl,
    'brand': brand,
    'packageSize': packageSize,
    'description': description,
    'stock': stock,
  };

  /// lấy giá trị đầu tiên khác null theo danh sách tên trường.
  static dynamic _pick(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json[key] != null) return json[key];
    }
    return null;
  }

  /// đổi số dạng int, double (36500.0) hoặc chuỗi thành int.
  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.round();
    return num.tryParse(value.toString())?.round();
  }

  /// đổi số dạng int, double hoặc chuỗi thành double.
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  /// nhận category là chuỗi, hoặc object `{"id":..,"name":..}` từ jpa.
  static String _readCategory(dynamic value) {
    if (value is Map) return value['name']?.toString() ?? '';
    return value?.toString() ?? '';
  }
}
