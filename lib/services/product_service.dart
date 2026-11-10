import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../data/sample_data.dart';
import '../models/product.dart';

class WarehouseOption {
  const WarehouseOption({required this.id, required this.name});

  final String id;
  final String name;
}

class ProductService {
  ProductService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  void dispose() => _apiClient.dispose();

  /// GET /products?category=&keyword=&warehouseId=
  Future<List<Product>> getProducts({
    String? category,
    String? keyword,
    String? warehouseId,
  }) async {
    final data = await _apiClient.get(
      ApiConstants.products,
      query: {
        'category': category,
        'keyword': keyword,
        'warehouseId': warehouseId,
      },
    );

    return _parseList(data);
  }

  /// GET /store/products → danh sách sản phẩm theo tồn kệ của cửa hàng đăng nhập.
  Future<List<Product>> getStoreProducts() async {
    final data = await _apiClient.get(ApiConstants.storeStock);
    return _parseList(data);
  }

  /// POST /products
  /// Không gửi id: PostgreSQL sẽ tạo UUID cho sản phẩm mới.
  Future<Product> createProduct({
    required String name,
    required int price,
    int? oldPrice,
    required int importPrice,
    required String barcode,
    required double rating,
    required String category,
    required String imageUrl,
    required String brand,
    required String packageSize,
    required String description,
    required int stock,
    required String warehouseId,
  }) async {
    final body = <String, dynamic>{
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
      'warehouseId': warehouseId,
    };

    final data = await _apiClient.post(ApiConstants.products, body: body);

    return _parseOne(data);
  }

  /// GET /warehouses
  Future<List<WarehouseOption>> getWarehouses() async {
    final data = await _apiClient.get(ApiConstants.warehouses);
    final dynamic items = data is Map ? data['content'] : data;

    if (items is! List) {
      throw const FormatException('Dữ liệu API không phải danh sách kho');
    }

    return items
        .whereType<Map>()
        .map((item) {
          final map = Map<String, dynamic>.from(item);

          return WarehouseOption(
            id: map['id']?.toString() ?? '',
            name: map['name']?.toString() ?? '',
          );
        })
        .where(
          (warehouse) => warehouse.id.isNotEmpty && warehouse.name.isNotEmpty,
        )
        .toList(growable: false);
  }

  /// Các API này chỉ sử dụng được khi backend đã triển khai endpoint tương ứng.
  Future<List<ProductCategory>> getCategories() async {
    final data = await _apiClient.get(ApiConstants.categories);
    return _parseCategories(data);
  }

  Future<Product> getProductById(String id) async {
    final data = await _apiClient.get(ApiConstants.productById(id));
    return _parseOne(data);
  }

  Future<Product> getProductByBarcode(String barcode) async {
    final data = await _apiClient.get(ApiConstants.productByBarcode(barcode));
    return _parseOne(data);
  }

  List<Product> _parseList(dynamic data) {
    final dynamic items = data is Map ? data['content'] : data;

    if (items is! List) {
      throw const FormatException('Dữ liệu API không phải danh sách sản phẩm');
    }

    return items
        .whereType<Map>()
        .map((item) => Product.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Product _parseOne(dynamic data) {
    if (data is! Map) {
      throw const FormatException('Dữ liệu API không phải một sản phẩm');
    }

    return Product.fromJson(Map<String, dynamic>.from(data));
  }

  List<ProductCategory> _parseCategories(dynamic data) {
    final dynamic items = data is Map ? data['content'] : data;

    if (items is! List) return [];

    return items
        .map((item) {
          if (item is Map) {
            final name =
                item['name']?.toString() ?? item['category']?.toString() ?? '';

            final countNum = item['count'] ?? item['productCount'];

            final count = countNum != null
                ? '$countNum sản phẩm'
                : (item['description']?.toString() ?? '');

            final emoji = item['emoji']?.toString() ?? _emojiForCategory(name);

            return ProductCategory(emoji: emoji, name: name, count: count);
          }

          final name = item.toString();

          return ProductCategory(
            emoji: _emojiForCategory(name),
            name: name,
            count: '',
          );
        })
        .where((category) => category.name.isNotEmpty)
        .toList();
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
