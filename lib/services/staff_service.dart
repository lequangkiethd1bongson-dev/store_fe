import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

/// Dịch vụ kết nối các API dành cho Nhân viên (Kệ hàng, Kho, Bán hàng POS, Chấm công).
class StaffService {
  StaffService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// GET /staff/shelves — Lấy sơ đồ kệ hàng và tầng từ backend.
  Future<dynamic> getShelves() async {
    return await _apiClient.get(ApiConstants.shelves);
  }

  /// GET /staff/warehouse — Lấy danh sách tồn kho dự trữ.
  Future<dynamic> getWarehouse() async {
    return await _apiClient.get(ApiConstants.warehouse);
  }

  /// GET /staff/stock-receipts — Lấy lịch sử nhập kho.
  Future<dynamic> getStockReceipts() async {
    return await _apiClient.get(ApiConstants.stockReceipts);
  }

  /// POST /staff/stock-receipts — Tiếp nhận kiện hàng mới nhập vào kho.
  Future<dynamic> receiveStock({
    required String productId,
    required int quantity,
  }) async {
    return await _apiClient.post(
      ApiConstants.stockReceipts,
      body: {'productId': productId, 'quantity': quantity},
    );
  }

  /// POST /staff/shelf-moves — Chuyển hàng từ kho dự trữ lên tầng kệ.
  Future<dynamic> moveToShelf({
    required String shelfCode,
    required int tier,
    required String productId,
    required int quantity,
  }) async {
    return await _apiClient.post(
      ApiConstants.shelfMoves,
      body: {
        'shelfCode': shelfCode,
        'tier': tier,
        'productId': productId,
        'quantity': quantity,
      },
    );
  }

  /// POST /staff/sales — Xuất hóa đơn bán lẻ POS tại quầy.
  Future<dynamic> completeSale({
    required List<Map<String, dynamic>> lines,
    required int total,
  }) async {
    return await _apiClient.post(
      ApiConstants.sales,
      body: {'lines': lines, 'total': total},
    );
  }

  /// POST /staff/attendance — Điểm danh / Chấm công ca làm.
  Future<dynamic> recordAttendance({
    required String type,
    DateTime? timestamp,
  }) async {
    return await _apiClient.post(
      ApiConstants.attendance,
      body: {
        'type': type,
        'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
      },
    );
  }
}
