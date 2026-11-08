import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/restock_models.dart';

/// Dịch vụ kết nối API Quản lý tồn kệ cửa hàng & Phiếu yêu cầu xuất hàng từ kho.
class RestockService {
  RestockService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient(),
      _ownsClient = apiClient == null;

  final ApiClient _apiClient;
  final bool _ownsClient;

  void dispose() {
    if (_ownsClient) _apiClient.dispose();
  }

  /// GET /store/products — Lấy danh sách tồn kệ tại cửa hàng hiện tại.
  Future<List<StoreStockItem>> getStoreStock({String? keyword}) async {
    final data = await _apiClient.get(
      ApiConstants.storeStock,
      query: {'keyword': keyword},
    );
    final dynamic items = data is Map ? data['content'] : data;

    if (items is! List) {
      throw const FormatException(
        'Dữ liệu tồn kệ từ API không phải dạng danh sách.',
      );
    }

    return items
        .whereType<Map>()
        .map((item) => StoreStockItem.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  /// POST /store/restock-requests — Tạo phiếu yêu cầu xuất hàng từ kho.
  Future<RestockRequest> createRequest({
    required String warehouseId,
    required List<Map<String, dynamic>> items,
    String? note,
  }) async {
    final body = <String, dynamic>{
      'warehouseId': warehouseId,
      'items': items,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    };

    final data = await _apiClient.post(
      ApiConstants.restockRequests,
      body: body,
    );

    if (data is! Map) {
      throw const FormatException(
        'Dữ liệu trả về từ API tạo phiếu yêu cầu không hợp lệ.',
      );
    }

    return RestockRequest.fromJson(Map<String, dynamic>.from(data));
  }

  /// GET /store/restock-requests?status= — Lấy danh sách phiếu cửa hàng hiện tại.
  Future<List<RestockRequest>> getRequests({String? status}) async {
    final data = await _apiClient.get(
      ApiConstants.restockRequests,
      query: {'status': status},
    );
    final dynamic items = data is Map ? data['content'] : data;

    if (items is! List) {
      throw const FormatException(
        'Dữ liệu phiếu yêu cầu từ API không phải dạng danh sách.',
      );
    }

    return items
        .whereType<Map>()
        .map((item) => RestockRequest.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  /// GET /store/restock-requests/{id} — Lấy chi tiết một phiếu yêu cầu.
  Future<RestockRequest> getRequestById(String id) async {
    final data = await _apiClient.get(ApiConstants.restockRequestById(id));
    if (data is! Map) {
      throw const FormatException(
        'Dữ liệu chi tiết phiếu yêu cầu không hợp lệ.',
      );
    }
    return RestockRequest.fromJson(Map<String, dynamic>.from(data));
  }

  /// POST /store/stock-exports/{exportId}/confirm-receipt.
  Future<RestockRequest> confirmReceipt({
    required String exportId,
    required String requestId,
  }) async {
    await _apiClient.post(ApiConstants.confirmStockReceipt(exportId));
    return getRequestById(requestId);
  }

  // ---------------------------------------------------------------------------
  // PHÂN HỆ QUẢN LÝ KHO (ROLE: WAREHOUSE_MANAGER / KHO_MANAGER)
  // ---------------------------------------------------------------------------

  /// GET /warehouse/restock-requests?status= — Lấy danh sách phiếu gửi tới kho phụ trách.
  Future<List<RestockRequest>> getWarehouseRequests({String? status}) async {
    final data = await _apiClient.get(
      ApiConstants.warehouseRestockRequests,
      query: {'status': status},
    );
    final dynamic items = data is Map ? data['content'] : data;

    if (items is! List) {
      throw const FormatException(
        'Dữ liệu phiếu yêu cầu từ kho API không phải dạng danh sách.',
      );
    }

    return items
        .whereType<Map>()
        .map((item) => RestockRequest.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  /// GET /warehouse/restock-requests/{id} — Lấy chi tiết phiếu phía kho.
  Future<RestockRequest> getWarehouseRequestById(String id) async {
    final data = await _apiClient.get(
      ApiConstants.warehouseRestockRequestById(id),
    );
    if (data is! Map) {
      throw const FormatException(
        'Dữ liệu chi tiết phiếu yêu cầu kho không hợp lệ.',
      );
    }
    return RestockRequest.fromJson(Map<String, dynamic>.from(data));
  }

  /// POST /warehouse/restock-requests/{id}/approve — Duyệt phiếu yêu cầu cấp hàng.
  Future<RestockRequest> approveRequest({
    required String requestId,
    required List<Map<String, dynamic>> items,
  }) async {
    final body = <String, dynamic>{'items': items};
    final data = await _apiClient.post(
      ApiConstants.approveWarehouseRestockRequest(requestId),
      body: body,
    );

    if (data is Map) {
      return RestockRequest.fromJson(Map<String, dynamic>.from(data));
    }
    return getWarehouseRequestById(requestId);
  }

  /// POST /warehouse/restock-requests/{id}/reject — Từ chối phiếu yêu cầu cấp hàng.
  Future<RestockRequest> rejectRequest({
    required String requestId,
    required String rejectReason,
  }) async {
    final body = <String, dynamic>{
      'rejectReason': rejectReason.trim(),
      'reason': rejectReason.trim(),
    };
    final data = await _apiClient.post(
      ApiConstants.rejectWarehouseRestockRequest(requestId),
      body: body,
    );

    if (data is Map) {
      return RestockRequest.fromJson(Map<String, dynamic>.from(data));
    }
    return getWarehouseRequestById(requestId);
  }

  /// POST /warehouse/restock-requests/{id}/export — Xuất kho gửi cửa hàng kèm danh sách mã vạch & số lượng đã quét.
  Future<RestockRequest> exportRequest({
    required String requestId,
    List<Map<String, dynamic>>? scannedItems,
  }) async {
    final body = scannedItems != null && scannedItems.isNotEmpty
        ? <String, dynamic>{
            'items': scannedItems,
            'barcodes': scannedItems,
          }
        : null;

    final data = await _apiClient.post(
      ApiConstants.exportWarehouseRestockRequest(requestId),
      body: body,
    );

    if (data is Map) {
      return RestockRequest.fromJson(Map<String, dynamic>.from(data));
    }
    return getWarehouseRequestById(requestId);
  }
}
