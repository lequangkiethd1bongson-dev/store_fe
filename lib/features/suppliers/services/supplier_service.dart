import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
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

  /// GET /suppliers → Lấy danh sách nhà cung cấp theo các query parameters Backend hỗ trợ.
  Future<List<Supplier>> getSuppliers({
    bool? isActive,
    bool? activeOnly,
    String? keyword,
    int? page,
    int? size,
    bool? includeHidden,
  }) async {
    final query = <String, String?>{};

    final effectiveIsActive = isActive ?? (activeOnly == true ? true : null);

    if (effectiveIsActive != null) {
      query['isActive'] = effectiveIsActive.toString();
    }
    if (keyword != null && keyword.trim().isNotEmpty) {
      query['keyword'] = keyword.trim();
    }
    if (page != null) {
      query['page'] = page.toString();
    }
    if (size != null) {
      query['size'] = size.toString();
    }
    if (includeHidden != null) {
      query['includeHidden'] = includeHidden.toString();
    }

    final data = await _apiClient.get(
      ApiConstants.suppliers,
      query: query.isNotEmpty ? query : null,
    );

    final dynamic items = data is Map
        ? (data['content'] ?? data['items'] ?? data['data'])
        : data;

    if (items is! List) {
      return [];
    }

    final list = items
        .whereType<Map>()
        .map((item) => Supplier.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    if (activeOnly == true) {
      return list.where((s) => s.isActive).toList();
    }
    return list;
  }

  /// GET /suppliers/{id} → Chi tiết nhà cung cấp.
  Future<Supplier> getSupplierById(String id) async {
    final data = await _apiClient.get('${ApiConstants.suppliers}/$id');

    if (data is Map) {
      return Supplier.fromJson(Map<String, dynamic>.from(data));
    }
    throw const ApiException('Không tìm thấy chi tiết nhà cung cấp.');
  }

  /// POST /suppliers → Thêm nhà cung cấp mới.
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
    };

    final data = await _apiClient.post(ApiConstants.suppliers, body: body);

    if (data is Map) {
      return Supplier.fromJson(Map<String, dynamic>.from(data));
    }
    throw const ApiException(
      'Dữ liệu nhà cung cấp mới trả về từ máy chủ không hợp lệ.',
    );
  }

  /// PUT /suppliers/{id} → Cập nhật thông tin nhà cung cấp.
  /// Gửi duy nhất field `isActive` (camelCase) theo chuẩn Backend DTO.
  Future<Supplier> updateSupplier({
    required String id,
    String? name,
    String? phone,
    String? address,
    String? email,
    String? fax,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (address != null && address.trim().isNotEmpty)
        'address': address.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (fax != null && fax.trim().isNotEmpty) 'fax': fax.trim(),
      'isActive': ?isActive,
    };

    final data = await _apiClient.put(
      '${ApiConstants.suppliers}/$id',
      body: body,
    );

    if (data is Map) {
      return Supplier.fromJson(Map<String, dynamic>.from(data));
    }
    throw const ApiException('Cập nhật thông tin nhà cung cấp thất bại.');
  }

  /// PUT /suppliers/{id} → Đổi trạng thái hoạt động / ngừng hoạt động.
  /// Gửi kèm đầy đủ name, phone, address để tránh bị Backend từ chối validation @NotBlank.
  Future<Supplier> toggleSupplierStatus({
    required String id,
    required bool isActive,
    String? name,
    String? phone,
    String? address,
    String? email,
  }) async {
    return updateSupplier(
      id: id,
      name: name,
      phone: phone,
      address: address,
      email: email,
      isActive: isActive,
    );
  }
}
