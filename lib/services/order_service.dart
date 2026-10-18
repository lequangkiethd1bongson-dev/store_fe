import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/product.dart';
import '../models/store_models.dart';

/// Dịch vụ gửi và lấy đơn hàng từ backend Java.
class OrderService {
  OrderService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// POST /orders — gửi đơn hàng mới lên backend.
  Future<StoreOrder?> createOrder({
    required List<CartLine> lines,
    required int total,
  }) async {
    final body = {
      'lines': lines
          .map((line) => {
                'productId': line.product.id,
                'quantity': line.quantity,
                'price': line.product.price,
              })
          .toList(),
      'total': total,
    };
    final data = await _apiClient.post(ApiConstants.orders, body: body);
    if (data is Map<String, dynamic>) {
      return _parseOrder(data);
    }
    return null;
  }

  /// GET /orders — lấy lịch sử đơn hàng của người dùng từ backend.
  Future<List<StoreOrder>> getOrders() async {
    final data = await _apiClient.get(ApiConstants.orders);
    final dynamic items = data is Map ? data['content'] : data;
    if (items is List) {
      return items
          .whereType<Map<String, dynamic>>()
          .map((item) => _parseOrder(item))
          .whereType<StoreOrder>()
          .toList();
    }
    return [];
  }

  /// PATCH /orders/{id}/cancel — hủy đơn hàng khi đang chờ xác nhận.
  Future<bool> cancelOrder(String orderId) async {
    try {
      await _apiClient.patch(ApiConstants.cancelOrder(orderId));
      return true;
    } catch (_) {
      return false;
    }
  }

  StoreOrder? _parseOrder(Map<String, dynamic> json) {
    try {
      final id = json['id']?.toString() ?? '';
      final total = (json['total'] as num?)?.toInt() ?? 0;
      final status = json['status']?.toString() ?? 'Chờ xác nhận';
      final createdAtStr = json['createdAt']?.toString();
      final createdAt = createdAtStr != null
          ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
          : DateTime.now();

      final rawLines = json['lines'] as List? ?? [];
      final lines = <CartLine>[];
      for (final raw in rawLines) {
        if (raw is Map<String, dynamic>) {
          final productJson = raw['product'];
          final product = productJson is Map<String, dynamic>
              ? Product.fromJson(productJson)
              : Product(
                  id: raw['productId']?.toString() ?? '',
                  name: raw['productName']?.toString() ?? 'Sản phẩm',
                  price: (raw['price'] as num?)?.toInt() ?? 0,
                  rating: 5.0,
                  category: 'Tổng hợp',
                  imageUrl: raw['imageUrl']?.toString() ?? '',
                );
          final quantity = (raw['quantity'] as num?)?.toInt() ?? 1;
          lines.add(CartLine(product: product, quantity: quantity));
        }
      }

      return StoreOrder(
        id: id,
        createdAt: createdAt,
        lines: lines,
        total: total,
        status: status,
      );
    } catch (_) {
      return null;
    }
  }
}
