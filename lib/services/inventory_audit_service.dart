import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/inventory_audit_models.dart';
import '../models/product.dart';

class InventoryAuditService {
  final String baseUrl = ApiConstants.baseUrl;

  Future<List<InventoryBalanceItem>> getBalanceReport() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/inventory/balance-report'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((e) => InventoryBalanceItem.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<Product>> getReorderAlerts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/inventory/reorder-alerts?threshold=10'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((e) => Product.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<StocktakeRecord>> getStocktakes() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/inventory/stocktakes'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((e) => StocktakeRecord.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> createStocktake(StocktakeRecord record) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/inventory/stocktakes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(record.toJson()),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}
