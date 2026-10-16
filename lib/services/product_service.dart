import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
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
}