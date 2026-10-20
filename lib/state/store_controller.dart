import 'package:flutter/foundation.dart';

import '../data/sample_data.dart';
import '../models/store_models.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';

/// quản lý trạng thái giỏ hàng và đơn mua dùng chung trong ứng dụng.
///
/// BƯỚC 5 — gọi [ProductService] và [OrderService] để liên kết với backend,
/// cập nhật danh sách [products] cùng trạng thái [isLoading] / [errorMessage].
class StoreController extends ChangeNotifier {
  StoreController({
    required List<Product> products,
    List<ProductCategory>? categories,
    Map<String, int> initialCart = const {},
    ProductService? productService,
    OrderService? orderService,
  }) : _products = List<Product>.of(products),
       _categories = List<ProductCategory>.of(categories ?? sampleCategories),
       _quantities = Map<String, int>.from(initialCart),
       _productService = productService ?? ProductService(),
       _orderService = orderService ?? OrderService();

  final ProductService _productService;
  final OrderService _orderService;
  List<Product> _products;
  List<ProductCategory> _categories;
  final Map<String, int> _quantities;
  final List<StoreOrder> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _loadedFromApi = false;

  /// danh sách sản phẩm đang hiển thị, lấy từ api hoặc dữ liệu mẫu.
  List<Product> get products => List.unmodifiable(_products);
  /// danh sách danh mục sản phẩm, lấy từ api hoặc dữ liệu mẫu.
  List<ProductCategory> get categories => List.unmodifiable(_categories);
  /// cho biết đang chờ backend trả danh sách sản phẩm.
  bool get isLoading => _isLoading;
  /// nội dung lỗi của lần tải gần nhất, null nếu thành công.
  String? get errorMessage => _errorMessage;
  /// cho biết danh sách hiện tại đã lấy được từ backend hay chưa.
  bool get loadedFromApi => _loadedFromApi;

  /// trả về bản sao chỉ đọc của số lượng từng sản phẩm trong giỏ.
  Map<String, int> get quantities => Map.unmodifiable(_quantities);
  /// trả về danh sách đơn hàng đã tạo trong phiên chạy hiện tại.
  List<StoreOrder> get orders => List.unmodifiable(_orders);
  /// cộng số lượng của mọi sản phẩm trong giỏ để hiện huy hiệu giỏ hàng.
  int get cartCount =>
      _quantities.values.fold(0, (sum, quantity) => sum + quantity);

  /// tạo các dòng hàng từ mã sản phẩm và số lượng hiện có trong giỏ.
  /// bỏ qua mã không còn trong danh sách để không lỗi khi dữ liệu đổi.
  List<CartLine> get cartLines {
    final byId = {for (final product in _products) product.id: product};
    return _quantities.entries
        .where((entry) => entry.value > 0 && byId.containsKey(entry.key))
        .map(
          (entry) => CartLine(product: byId[entry.key]!, quantity: entry.value),
        )
        .toList(growable: false);
  }

  /// cộng thành tiền của tất cả dòng hàng trong giỏ.
  int get subtotal => cartLines.fold(0, (sum, line) => sum + line.total);
  /// trả phí giao hàng mẫu, bằng không khi giỏ hàng đang trống.
  int get deliveryFee => _quantities.isEmpty ? 0 : 10000;
  /// tính tổng tiền hàng và phí giao hàng mẫu.
  int get total => subtotal + deliveryFee;

  /// gọi api `GET /products` và `GET /categories` rồi thay dữ liệu trên giao diện.
  ///
  /// nếu backend chưa chạy hoặc lỗi, giữ nguyên dữ liệu đang có (dữ liệu
  /// mẫu) và lưu lỗi vào [errorMessage] để ứng dụng vẫn dùng được.
  Future<void> loadProducts({String? category, String? keyword}) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _productService.getProducts(
        category: category,
        keyword: keyword,
      );
      if (result.isNotEmpty) {
        _products = List<Product>.of(result);
      }
      _loadedFromApi = true;

      // Nạp thêm danh mục sản phẩm từ backend
      try {
        final categoryList = await _productService.getCategories();
        if (categoryList.isNotEmpty) {
          _categories = List<ProductCategory>.of(categoryList);
        }
      } catch (catErr) {
        debugPrint('Chưa lấy được danh mục từ API: $catErr');
      }

      // xóa khỏi giỏ các sản phẩm mà backend không còn trả về.
      final ids = _products.map((product) => product.id).toSet();
      _quantities.removeWhere((id, _) => !ids.contains(id));
    } catch (error) {
      _errorMessage = error.toString();
      debugPrint('Không tải được sản phẩm từ API: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Nạp danh sách đơn hàng từ backend Java.
  Future<void> loadOrders() async {
    try {
      final remoteOrders = await _orderService.getOrders();
      if (remoteOrders.isNotEmpty) {
        _orders.clear();
        _orders.addAll(remoteOrders);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Chưa lấy được đơn hàng từ API: $e');
    }
  }

  /// tải lại sản phẩm từ backend khi người dùng kéo để làm mới.
  Future<void> refreshDemoData() async {
    await loadProducts();
    await loadOrders();
  }

  /// tìm sản phẩm theo mã định danh hoặc báo lỗi nếu mã không tồn tại.
  Product productById(String id) {
    return _products.firstWhere(
      (product) => product.id == id,
      orElse: () => Product(
        id: id,
        name: 'Sản phẩm $id',
        price: 0,
        rating: 5.0,
        category: 'Hàng hóa',
        imageUrl: 'assets/images/logosieuthi.png',
      ),
    );
  }

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

  /// tạo đơn mua, gửi lên backend nếu có kết nối, lưu bản sao các dòng hàng rồi làm trống giỏ.
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

    // Gửi đơn mua lên backend không đồng bộ
    _orderService.createOrder(lines: cartLines, total: order.total).catchError((e) {
      debugPrint('Tạo đơn hàng online thất bại (chuyển sang chế độ local): $e');
      return null;
    });

    clearCart();
    notifyListeners();
    return order;
  }
}
