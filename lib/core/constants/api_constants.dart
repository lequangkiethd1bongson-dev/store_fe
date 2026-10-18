/// BƯỚC 1 — khai báo địa chỉ backend java và toàn bộ đường dẫn api.
///
/// quy ước chung để backend (spring boot) làm theo:
/// - tiền tố mọi api: `/api`, cổng mặc định `8080`.
/// - dữ liệu gửi và nhận đều là json, header `Content-Type: application/json`.
/// - tên trường json viết kiểu camelCase (mặc định của jackson), ví dụ
///   `oldPrice`, `imageUrl`, `createdAt`.
/// - tiền là số nguyên vnđ (36500), không gửi chuỗi "36.500đ".
/// - thời gian theo iso-8601, ví dụ `2026-10-16T18:09:14`.
/// - api trả danh sách thì body là mảng json `[...]`, không bọc thêm lớp.
/// - lỗi trả mã http 4xx/5xx kèm body `{"message": "nội dung lỗi"}`.
/// - api cần đăng nhập đọc header `Authorization: Bearer <token>`.
///
/// xem chi tiết hợp đồng api trong tệp `docs/BACKEND_API_GUIDE.md`.
class ApiConstants {
  ApiConstants._();

  /// `10.0.2.2` là địa chỉ máy tính khi chạy trên máy ảo android.
  /// chạy trên điện thoại thật thì đổi thành ip lan của máy chạy backend,
  /// ví dụ `http://192.168.1.10:8080/api`.
  ///static const String baseUrl = 'http://10.0.2.2:8080/api';
  static const String baseUrl = 'http://192.168.1.25:8080/api';

  /// thời gian chờ tối đa cho một yêu cầu http.
  static const Duration timeout = Duration(seconds: 15);

  // ---------------------------------------------------------------------------
  // SẢN PHẨM & DANH MỤC (khách hàng) — đã nối vào giao diện.
  // ---------------------------------------------------------------------------

  /// GET  /products?category=&keyword=  → danh sách sản phẩm.
  static const String products = '/products';

  /// GET  /products/{id}  → chi tiết một sản phẩm.
  static String productById(String id) => '/products/$id';

  /// GET  /products/barcode/{barcode}  → tìm sản phẩm theo mã vạch.
  static String productByBarcode(String barcode) =>
      '/products/barcode/$barcode';

  /// GET  /categories  → danh sách nhóm hàng kèm số lượng sản phẩm.
  static const String categories = '/categories';

  // ---------------------------------------------------------------------------
  // TÀI KHOẢN — giao diện đã có, chờ backend.
  // ---------------------------------------------------------------------------

  /// POST /auth/login     body: {account, password}
  static const String login = '/auth/login';

  /// POST /auth/register  body: {name, account, password}
  static const String register = '/auth/register';

  /// GET  /users/me  → thông tin người đang đăng nhập.
  static const String me = '/users/me';

  /// GET / POST  /users/me/addresses  → địa chỉ giao hàng đã lưu.
  static const String myAddresses = '/users/me/addresses';

  // ---------------------------------------------------------------------------
  // ĐƠN HÀNG (khách hàng) — giao diện đã có, chờ backend.
  // ---------------------------------------------------------------------------

  /// GET  /orders?status=  → lịch sử đơn của người đang đăng nhập.
  /// POST /orders          → đặt đơn mới từ giỏ hàng.
  static const String orders = '/orders';

  /// GET  /orders/{id}  → chi tiết đơn.
  static String orderById(String id) => '/orders/$id';

  /// PATCH /orders/{id}/cancel  → khách hủy đơn đang chờ xác nhận.
  static String cancelOrder(String id) => '/orders/$id/cancel';

  // ---------------------------------------------------------------------------
  // KHU NHÂN VIÊN (ROLE: STAFF) — chỉ tài khoản nhân viên mới được gọi.
  // Nếu tài khoản CUSTOMER gọi vào các API này, backend cần trả về 403 Forbidden.
  // ---------------------------------------------------------------------------

  /// GET  /staff/shelves  → danh sách kệ (A1-A3, B1-B3, C1-C3), sức chứa và hàng trên từng tầng (1-4).
  static const String shelves = '/staff/shelves';

  /// GET  /staff/warehouse  → tồn kho dự trữ theo từng sản phẩm.
  static const String warehouse = '/staff/warehouse';

  /// GET  /staff/stock-receipts?productId=  → lịch sử các lần tiếp nhận hàng vào kho.
  /// POST /staff/stock-receipts             → nhập hàng mới vào kho (productId, quantity).
  static const String stockReceipts = '/staff/stock-receipts';

  /// POST /staff/shelf-moves  → chuyển hàng từ kho dự trữ lên 1 tầng kệ cụ thể.
  /// body: { shelfCode: "A1", tier: 1, productId: "milk", quantity: 6 }
  /// Ràng buộc: kiểm tra kho đủ hàng và tầng đó chưa bị trùng sản phẩm khác.
  static const String shelfMoves = '/staff/shelf-moves';

  /// GET  /staff/sales  → danh sách hóa đơn bán tại quầy POS.
  /// POST /staff/sales  → xuất hóa đơn bán lẻ tại quầy, trừ hàng trực tiếp trên kệ.
  static const String sales = '/staff/sales';

  /// GET / POST /staff/attendance  → chấm công / điểm danh ca làm của nhân viên.
  /// body: { staffId, type: "CHECK_IN" | "CHECK_OUT", timestamp }
  static const String attendance = '/staff/attendance';
}