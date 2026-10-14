/// lưu thông tin sản phẩm, dòng giỏ hàng và đơn mua trong ứng dụng.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.rating,
    required this.category,
    required this.imageUrl,
    this.oldPrice,
    this.barcode,
    this.brand,
    this.packageSize,
    this.description,
    this.stock = 24,
  });

  final String id;
  final String name;
  final int price;
  final int? oldPrice;
  final String? barcode;
  final double rating;
  final String category;
  final String imageUrl;
  final String? brand;
  final String? packageSize;
  final String? description;
  final int stock;

  /// tính phần trăm giảm giá nếu giá cũ lớn hơn giá hiện tại.
  int? get discountPercent {
    final previousPrice = oldPrice;
    if (previousPrice == null || previousPrice <= price) return null;
    return ((previousPrice - price) / previousPrice * 100).round();
  }
}

/// biểu diễn một sản phẩm cùng số lượng đang có trong giỏ hoặc đơn hàng.
class CartLine {
  const CartLine({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  /// tính thành tiền của dòng hàng này.
  int get total => product.price * quantity;
}

/// lưu mã, thời điểm, các dòng sản phẩm và trạng thái của đơn mua.
class StoreOrder {
  const StoreOrder({
    required this.id,
    required this.createdAt,
    required this.lines,
    required this.total,
    this.status = 'Chờ xác nhận',
  });

  final String id;
  final DateTime createdAt;
  final List<CartLine> lines;
  final int total;
  final String status;
}

/// đổi số tiền nguyên sang chuỗi tiền việt có dấu phân cách hàng nghìn.
String formatVnd(int amount) {
  final digits = amount.abs().toString();
  final groups = <String>[];
  for (var end = digits.length; end > 0; end -= 3) {
    final start = end - 3 < 0 ? 0 : end - 3;
    groups.insert(0, digits.substring(start, end));
  }
  final sign = amount < 0 ? '−' : '';
  return '$sign${groups.join('.')}đ';
}
