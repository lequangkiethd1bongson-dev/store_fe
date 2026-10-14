import 'package:flutter/foundation.dart';

import '../models/store_models.dart';

/// quản lý trạng thái giỏ hàng và đơn mua mẫu dùng chung trong ứng dụng.
class StoreController extends ChangeNotifier {
  StoreController({
    required this.products,
    Map<String, int> initialCart = const {},
  }) : _quantities = Map<String, int>.from(initialCart);

  final List<Product> products;
  final Map<String, int> _quantities;
  final List<StoreOrder> _orders = [];

  /// trả về bản sao chỉ đọc của số lượng từng sản phẩm trong giỏ.
  Map<String, int> get quantities => Map.unmodifiable(_quantities);
  /// trả về danh sách đơn hàng đã tạo trong phiên chạy hiện tại.
  List<StoreOrder> get orders => List.unmodifiable(_orders);
  /// cộng số lượng của mọi sản phẩm trong giỏ để hiện huy hiệu giỏ hàng.
  int get cartCount =>
      _quantities.values.fold(0, (sum, quantity) => sum + quantity);

  /// tạo các dòng hàng từ mã sản phẩm và số lượng hiện có trong giỏ.
  List<CartLine> get cartLines => _quantities.entries
      .where((entry) => entry.value > 0)
      .map(
        (entry) =>
            CartLine(product: productById(entry.key), quantity: entry.value),
      )
      .toList(growable: false);

  /// cộng thành tiền của tất cả dòng hàng trong giỏ.
  int get subtotal => cartLines.fold(0, (sum, line) => sum + line.total);
  /// trả phí giao hàng mẫu, bằng không khi giỏ hàng đang trống.
  int get deliveryFee => _quantities.isEmpty ? 0 : 10000;
  /// tính tổng tiền hàng và phí giao hàng mẫu.
  int get total => subtotal + deliveryFee;

  /// mô phỏng tải lại dữ liệu bằng một khoảng chờ ngắn rồi báo giao diện cập nhật.
  Future<void> refreshDemoData() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    notifyListeners();
  }

  /// tìm sản phẩm theo mã định danh hoặc báo lỗi nếu mã không tồn tại.
  Product productById(String id) =>
      products.firstWhere((product) => product.id == id);

  /// thêm số lượng sản phẩm vào giỏ rồi thông báo các màn hình đang nghe.
  void addToCart(Product product, {int quantity = 1}) {
    if (quantity < 1) return;
    _quantities.update(
      product.id,
      (current) => current + quantity,
      ifAbsent: () => quantity,
    );
    notifyListeners();
  }

  /// đặt số lượng mới cho sản phẩm hoặc xóa sản phẩm nếu số lượng không dương.
  void setQuantity(Product product, int quantity) {
    if (quantity <= 0) {
      _quantities.remove(product.id);
    } else {
      _quantities[product.id] = quantity;
    }
    notifyListeners();
  }

  /// xóa một sản phẩm khỏi giỏ và cập nhật giao diện.
  void removeFromCart(Product product) {
    _quantities.remove(product.id);
    notifyListeners();
  }

  /// xóa toàn bộ nội dung giỏ hàng và cập nhật giao diện.
  void clearCart() {
    _quantities.clear();
    notifyListeners();
  }

  /// tạo đơn mua mẫu, lưu bản sao các dòng hàng rồi làm trống giỏ.
  StoreOrder placeDemoOrder({int deliveryFee = 10000}) {
    if (_quantities.isEmpty) {
      throw StateError('Không thể đặt hàng khi giỏ hàng trống.');
    }
    final order = StoreOrder(
      id: 'SM${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      createdAt: DateTime.now(),
      lines: List<CartLine>.unmodifiable(cartLines),
      total: subtotal + deliveryFee,
    );
    _orders.insert(0, order);
    clearCart();
    notifyListeners();
    return order;
  }
}
