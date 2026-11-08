import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/goods_receipt_models.dart';

class GoodsReceiptService {
  GoodsReceiptService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient(),
      _ownsClient = apiClient == null;

  final ApiClient _apiClient;
  final bool _ownsClient;

  void dispose() {
    if (_ownsClient) _apiClient.dispose();
  }

  /// GET /warehouse/goods-receipts?status=&search=&warehouseId=
  Future<List<GoodsReceipt>> getGoodsReceipts({
    String? status,
    String? search,
    String? warehouseId,
  }) async {
    final query = <String, String?>{};
    if (status != null && status.isNotEmpty && status != 'ALL') {
      query['status'] = status;
    }
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
      query['keyword'] = search.trim();
    }
    if (warehouseId != null && warehouseId.isNotEmpty) {
      query['warehouseId'] = warehouseId;
    }

    final data = await _apiClient.get(
      ApiConstants.warehouseGoodsReceipts,
      query: query.isNotEmpty ? query : null,
    );

    final dynamic items =
        data is Map ? (data['content'] ?? data['items'] ?? data['data']) : data;

    if (items is! List) {
      return [];
    }

    final list =
        items
            .whereType<Map>()
            .map(
              (item) => GoodsReceipt.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// GET /warehouse/goods-receipts/{id}
  Future<GoodsReceipt> getGoodsReceiptById(String id) async {
    final data = await _apiClient.get(
      ApiConstants.warehouseGoodsReceiptById(id),
    );
    if (data is Map) {
      return GoodsReceipt.fromJson(Map<String, dynamic>.from(data));
    }
    throw const ApiException('Không tìm thấy chi tiết phiếu nhập.');
  }

  /// POST /warehouse/goods-receipts -> Tạo phiếu Nháp
  Future<GoodsReceipt> createDraftReceipt({
    required String warehouseId,
    required String supplierId,
    String? note,
    required List<Map<String, dynamic>> items,
  }) async {
    final body = <String, dynamic>{
      'warehouseId': warehouseId,
      'warehouse_id': warehouseId,
      'supplierId': supplierId,
      'supplier_id': supplierId,
      'note': note ?? '',
      'items': items,
    };

    final data = await _apiClient.post(
      ApiConstants.warehouseGoodsReceipts,
      body: body,
    );

    if (data is Map) {
      return GoodsReceipt.fromJson(Map<String, dynamic>.from(data));
    }
    throw const ApiException('Tạo phiếu nhập nháp thất bại.');
  }

  /// PUT /warehouse/goods-receipts/{id} -> Chỉnh sửa phiếu Nháp
  Future<GoodsReceipt> updateDraftReceipt({
    required String receiptId,
    String? warehouseId,
    String? supplierId,
    String? note,
    required List<Map<String, dynamic>> items,
  }) async {
    final body = <String, dynamic>{
      if (warehouseId != null) ...{
        'warehouseId': warehouseId,
        'warehouse_id': warehouseId,
      },
      if (supplierId != null) ...{
        'supplierId': supplierId,
        'supplier_id': supplierId,
      },
      'note': note ?? '',
      'items': items,
    };

    final data = await _apiClient.put(
      ApiConstants.warehouseGoodsReceiptById(receiptId),
      body: body,
    );

    if (data is Map) {
      return GoodsReceipt.fromJson(Map<String, dynamic>.from(data));
    }
    throw const ApiException('Cập nhật phiếu nháp thất bại.');
  }

  /// POST /warehouse/goods-receipts/{id}/complete -> Hoàn tất nhập kho
  Future<GoodsReceipt> completeGoodsReceipt(String receiptId) async {
    final data = await _apiClient.post(
      ApiConstants.completeWarehouseGoodsReceipt(receiptId),
    );

    if (data is Map) {
      return GoodsReceipt.fromJson(Map<String, dynamic>.from(data));
    }
    throw const ApiException('Xác nhận hoàn tất nhập kho thất bại.');
  }

  /// POST /warehouse/goods-receipts/{id}/cancel -> Hủy phiếu nháp
  Future<GoodsReceipt> cancelGoodsReceipt(
    String receiptId, {
    String? reason,
  }) async {
    final body =
        reason != null && reason.trim().isNotEmpty
            ? {'reason': reason.trim(), 'rejectReason': reason.trim()}
            : null;

    final data = await _apiClient.post(
      ApiConstants.cancelWarehouseGoodsReceipt(receiptId),
      body: body,
    );

    if (data is Map) {
      return GoodsReceipt.fromJson(Map<String, dynamic>.from(data));
    }
    throw const ApiException('Hủy phiếu nhập thất bại.');
  }
}
