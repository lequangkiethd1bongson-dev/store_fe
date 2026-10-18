import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../data/sample_data.dart';
import '../models/product.dart';

/// BƯỚC 4 — gọi api sản phẩm và chuyển json thành danh sách [Product].
///
/// service chỉ lo việc "lấy dữ liệu", không giữ trạng thái giao diện;
/// phần lưu danh sách và trạng thái tải nằm ở `StoreController` (bước 5).
class ProductService {
  ProductService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// GET /products?category=&keyword=
  ///
  /// backend trả mảng json các sản phẩm. hai tham số đều tùy chọn:
  /// bỏ trống thì trả toàn bộ sản phẩm đang bán.
  Future<List<Product>> getProducts({String? category, String? keyword}) async {
    final data = await _apiClient.get(
      ApiConstants.products,
      query: {'category': category, 'keyword': keyword},
    );
    return _parseList(data);
  }

  /// GET /categories — danh sách nhóm hàng kèm số lượng sản phẩm.
  Future<List<ProductCategory>> getCategories() async {
    final data = await _apiClient.get(ApiConstants.categories);
    return _parseCategories(data);
  }

  /// GET /products/{id} — trả một object sản phẩm, 404 nếu không có.
  Future<Product> getProductById(String id) async {
    final data = await _apiClient.get(ApiConstants.productById(id));
    return _parseOne(data);
  }

  /// GET /products/barcode/{barcode} — dùng cho màn quét mã vạch.
  Future<Product> getProductByBarcode(String barcode) async {
    final data = await _apiClient.get(ApiConstants.productByBarcode(barcode));
    return _parseOne(data);
  }

  /// POST /products — tạo hoặc thêm sản phẩm mới vào backend.
  Future<Product> createProduct(Product product) async {
    final data = await _apiClient.post(
      ApiConstants.products,
      body: product.toJson(),
    );
    if (data is Map) {
      return Product.fromJson(Map<String, dynamic>.from(data));
    }
    return product;
  }

  /// đổi body json thành danh sách, chấp nhận cả mảng trần hoặc trang
  /// phân trang của spring (`{"content": [...]}`).
  List<Product> _parseList(dynamic data) {
    final dynamic items = data is Map ? data['content'] : data;
    if (items is! List) {
      throw const FormatException(
        'Dữ liệu API không phải danh sách sản phẩm',
      );
    }
    return items
        .whereType<Map>()
        .map((item) => Product.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  /// đổi body json thành một sản phẩm.
  Product _parseOne(dynamic data) {
    if (data is! Map) {
      throw const FormatException('Dữ liệu API không phải một sản phẩm');
    }
    return Product.fromJson(Map<String, dynamic>.from(data));
  }

  /// đổi mảng json danh mục thành danh sách [ProductCategory].
  List<ProductCategory> _parseCategories(dynamic data) {
    final dynamic items = data is Map ? data['content'] : data;
    if (items is! List) return [];
    return items.map((item) {
      if (item is Map) {
        final name = item['name']?.toString() ?? item['category']?.toString() ?? '';
        final countNum = item['count'] ?? item['productCount'];
        final count = countNum != null ? '$countNum sản phẩm' : (item['description']?.toString() ?? '');
        final emoji = item['emoji']?.toString() ?? _emojiForCategory(name);
        return ProductCategory(emoji: emoji, name: name, count: count);
      } else {
        final name = item.toString();
        return ProductCategory(emoji: _emojiForCategory(name), name: name, count: '');
      }
    }).where((cat) => cat.name.isNotEmpty).toList();
  }

  static String _emojiForCategory(String name) {
    if (name.contains('Rau') || name.contains('quả')) return '🥬';
    if (name.contains('Thịt') || name.contains('cá')) return '🥩';
    if (name.contains('Sữa') || name.contains('trứng')) return '🥛';
    if (name.contains('Đồ uống') || name.contains('Nước')) return '🧃';
    if (name.contains('Bánh') || name.contains('kẹo')) return '🍪';
    if (name.contains('Gia vị')) return '🧂';
    if (name.contains('dụng')) return '🧹';
    if (name.contains('mỹ phẩm')) return '🧴';
    return '🛒';
  }
}