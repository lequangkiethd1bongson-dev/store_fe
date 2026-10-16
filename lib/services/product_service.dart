import 'dart:convert';

import '../core/network/api_client.dart';
import '../models/product.dart';

class ProductService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Product>> getProducts() async {
    final response = await _apiClient.get('/products');

    if (response.statusCode != 200) {
      throw Exception(
        'Lỗi lấy sản phẩm: HTTP ${response.statusCode}',
      );
    }

    final dynamic data = jsonDecode(response.body);

    if (data is! List) {
      throw const FormatException(
        'Dữ liệu API không phải danh sách sản phẩm',
      );
    }

    return data.map((item) {
      return Product.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
    }).toList();
  }
}