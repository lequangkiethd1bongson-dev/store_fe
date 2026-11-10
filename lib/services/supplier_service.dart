import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/supplier.dart';

class SupplierService {
  SupplierService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient(),
      _ownsClient = apiClient == null;

  final ApiClient _apiClient;
  final bool _ownsClient;

  void dispose() {
    if (_ownsClient) _apiClient.dispose();
  }

  /// GET /suppliers (hoặc GET /admin/suppliers) → Lấy danh sách nhà cung cấp.
  Future<List<Supplier>> getSuppliers({bool activeOnly = false}) async {
    dynamic data;
    try {
      data = await _apiClient.get(
        ApiConstants.suppliers,
        query: activeOnly ? {'active': 'true', 'status': 'active'} : null,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        data = await _apiClient.get(ApiConstants.adminSuppliers);
      } else {
        debugPrint('Backend API getSuppliers lỗi: $e. Thử đọc từ Supabase...');
      }
    } catch (e) {
      debugPrint('Backend API không phản hồi: $e. Đọc từ Supabase...');
    }

    if (data == null) {
      try {
        final res = await Supabase.instance.client.from('suppliers').select();
        if (res is List) {
          final list = res
              .whereType<Map>()
              .map((item) => Supplier.fromJson(Map<String, dynamic>.from(item)))
              .toList();
          return activeOnly ? list.where((s) => s.isActive).toList() : list;
        }
      } catch (e) {
        debugPrint('Lỗi đọc bảng suppliers trên Supabase: $e');
      }
      return [];
    }

    final dynamic items =
        data is Map ? (data['content'] ?? data['items'] ?? data['data']) : data;

    if (items is! List) {
      return [];
    }

    final suppliers =
        items
            .whereType<Map>()
            .map((item) => Supplier.fromJson(Map<String, dynamic>.from(item)))
            .toList();

    if (activeOnly) {
      return suppliers.where((s) => s.isActive).toList();
    }
    return suppliers;
  }

  /// POST /admin/suppliers → Thêm nhà cung cấp mới (Chỉ Admin).
  Future<Supplier> createSupplier({
    required String name,
    required String phone,
    required String address,
    String? email,
    String? fax,
    bool isActive = true,
  }) async {
    final body = <String, dynamic>{
      'name': name.trim(),
      'phone': phone.trim(),
      'address': address.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (fax != null && fax.trim().isNotEmpty) 'fax': fax.trim(),
      'isActive': isActive,
      'is_active': isActive,
    };

    dynamic data;
    try {
      data = await _apiClient.post(ApiConstants.adminSuppliers, body: body);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        data = await _apiClient.post(ApiConstants.suppliers, body: body);
      } else {
        debugPrint('Backend createSupplier lỗi: $e');
      }
    } catch (e) {
      debugPrint('Backend createSupplier offline: $e');
    }

    if (data is Map) {
      return Supplier.fromJson(Map<String, dynamic>.from(data));
    }

    // Fallback: ghi trực tiếp vào Supabase database
    try {
      final res = await Supabase.instance.client.from('suppliers').insert({
        'name': name.trim(),
        'phone': phone.trim(),
        'address': address.trim(),
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      }).select().single();
      return Supplier.fromJson(Map<String, dynamic>.from(res));
    } catch (e) {
      throw ApiException('Không thể lưu nhà cung cấp: $e');
    }
  }
}
