class ApiConstants {
  ApiConstants._();

  /// Địa chỉ Backend API:
  /// 1. Nếu chạy trên ĐIỆN THOẠI THẬT (Cắm cáp USB):
  ///    mở Terminal trên máy tính gõ lệnh: `adb reverse tcp:8080 tcp:8080`
  ///    rồi dùng: 'http://127.0.0.1:8080/api'
  /// 2. Nếu chạy trên ĐIỆN THOẠI THẬT (Cùng Wi-Fi):
  ///    đổi thành IP LAN máy tính của bạn (VD: 'http://192.168.1.7:8080/api')
  /// 3. Nếu chạy trên MÁY ẢO Android (Emulator):
  ///    dùng: 'http://10.0.2.2:8080/api'
  //static const String baseUrl = 'http://10.100.3.212:8080/api';
  static const String baseUrl = String.fromEnvironment(
    'BACKEND_API_URL',
    defaultValue: 'http://10.0.2.2:8080/api',
  );
  // static const String baseUrl = 'http://127.0.0.1:8080/api';
  // static const String baseUrl = 'http://192.168.1.7:8080/api';
  /// thời gian chờ tối đa cho một yêu cầu http.
  static const Duration timeout = Duration(seconds: 20);

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
  static const String warehouses = '/warehouses';
  static const String stores = '/stores';
  // ---------------------------------------------------------------------------
  // TÀI KHOẢN — giao diện đã có, chờ backend.
  // ---------------------------------------------------------------------------

  /// POST /auth/login     body: {account, password}
  static const String login = '/auth/login';

  /// POST /auth/register  body: {name, account, password}
  static const String register = '/auth/register';

  /// GET  /users/me  → thông tin người đang đăng nhập.
  static const String me = '/auth/me';

  /// GET / POST  /users/me/addresses  → địa chỉ giao hàng đã lưu.
  static const String myAddresses = '/auth/me/addresses';

  // ---------------------------------------------------------------------------
  // ĐƠN HÀNG (khách hàng) — giao diện đã có, chờ backend.
  // ---------------------------------------------------------------------------

  /// GET  /orders?status=  → lịch sử đơn của người đang đăng nhập.
  /// POST /orders          → đặt đơn mới từ giỏ hàng.
  static const String orders = '/orders';

  /// GET  /orders/{id}  → chi tiết đơn.
  // static String orderById(String id) => '/orders/$id';
  //
  // /// PATCH /orders/{id}/cancel  → khách hủy đơn đang chờ xác nhận.
  // static String cancelOrder(String id) => '/orders/$id/cancel';

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

  // ---------------------------------------------------------------------------
  // QUẢN LÝ CỬA HÀNG & PHIẾU YÊU CẦU HÀNG (ROLE: STORE_MANAGER / SALES)
  // ---------------------------------------------------------------------------

  /// GET /store/products?keyword= → sản phẩm và tồn kệ cửa hàng hiện tại.
  static const String storeStock = '/store/products';

  /// GET / POST /store/restock-requests → danh sách hoặc tạo phiếu yêu cầu.
  static const String restockRequests = '/store/restock-requests';

  /// GET /store/restock-requests/{id} → chi tiết một phiếu yêu cầu.
  static String restockRequestById(String id) => '/store/restock-requests/$id';

  /// POST /store/stock-exports/{exportId}/confirm-receipt.
  static String confirmStockReceipt(String exportId) =>
      '/store/stock-exports/$exportId/confirm-receipt';

  // ---------------------------------------------------------------------------
  // QUẢN LÝ KHO TIẾP NHẬN & XỬ LÝ PHIẾU YÊU CẦU (ROLE: WAREHOUSE_MANAGER / KHO_MANAGER)
  // ---------------------------------------------------------------------------

  /// GET /warehouse/restock-requests?status= → danh sách phiếu yêu cầu gửi đến kho.
  static const String warehouseRestockRequests = '/warehouse/restock-requests';

  /// GET /warehouse/restock-requests/{id} → chi tiết phiếu yêu cầu tại kho.
  static String warehouseRestockRequestById(String id) =>
      '/warehouse/restock-requests/$id';

  /// POST /warehouse/restock-requests/{id}/approve → duyệt phiếu yêu cầu.
  static String approveWarehouseRestockRequest(String id) =>
      '/warehouse/restock-requests/$id/approve';

  /// POST /warehouse/restock-requests/{id}/reject → từ chối phiếu yêu cầu.
  static String rejectWarehouseRestockRequest(String id) =>
      '/warehouse/restock-requests/$id/reject';

  /// POST /warehouse/restock-requests/{id}/export → xuất kho gửi cửa hàng.
  static String exportWarehouseRestockRequest(String id) =>
      '/warehouse/restock-requests/$id/export';

  // ---------------------------------------------------------------------------
  // NHÀ CUNG CẤP & PHIẾU NHẬP HÀNG TỪ NHÀ CUNG CẤP (ROLE: ADMIN / WAREHOUSE_MANAGER / KHO)
  // ---------------------------------------------------------------------------

  /// GET / POST /suppliers → danh sách & quản lý nhà cung cấp.
  static const String suppliers = '/suppliers';

  /// Lối tắt hướng về /suppliers (Backend không dùng /admin/suppliers).
  static const String adminSuppliers = '/suppliers';

  /// GET / POST /warehouse/goods-receipts → danh sách & tạo phiếu nhập kho mới.
  static const String warehouseGoodsReceipts = '/warehouse/goods-receipts';

  /// GET / PUT /warehouse/goods-receipts/{id} → chi tiết & cập nhật phiếu nháp.
  static String warehouseGoodsReceiptById(String id) =>
      '/warehouse/goods-receipts/$id';

  /// POST /warehouse/goods-receipts/{id}/complete → xác nhận hoàn tất nhập kho.
  static String completeWarehouseGoodsReceipt(String id) =>
      '/warehouse/goods-receipts/$id/complete';

  /// POST /warehouse/goods-receipts/{id}/cancel → hủy phiếu nháp.
  static String cancelWarehouseGoodsReceipt(String id) =>
      '/warehouse/goods-receipts/$id/cancel';

  // ---------------------------------------------------------------------------
  // QUẢN LÝ NHÂN SỰ, PHÂN LỊCH CA, BẢNG CÔNG TÍNH LƯƠNG & HỒ SƠ (ROLE: ADMIN / MANAGER / STAFF)
  // ---------------------------------------------------------------------------

  /// GET / POST /admin/employees → Danh sách & tạo tài khoản nhân viên mới.
  static const String adminEmployees = '/admin/employees';

  /// GET / PUT /admin/employees/{id} → Xem & cập nhật hồ sơ/phân công nhân viên.
  static String adminEmployeeById(String id) => '/admin/employees/$id';

  /// PATCH /admin/employees/{id}/status → Kích hoạt hoặc khóa tài khoản (is_active).
  static String adminEmployeeStatus(String id) =>
      '/admin/employees/$id/status';

  /// POST /admin/employees/{id}/change-password → Admin đổi mật khẩu cho nhân viên.
  static String adminEmployeeChangePassword(String id) =>
      '/admin/employees/$id/change-password';

  /// GET / POST /admin/shifts → Danh sách lịch phân ca & gán ca làm việc.
  static const String adminShifts = '/admin/shifts';

  /// POST /admin/shifts/bulk → Xếp lịch làm việc hàng loạt theo tuần/tháng.
  static const String adminShiftsBulk = '/admin/shifts/bulk';

  /// GET /admin/timesheets → Danh sách bảng chấm công & tính lương hàng tháng.
  static const String adminTimesheets = '/admin/timesheets';

  /// PUT /admin/timesheets/{id} → Cập nhật chi tiết bảng công & phụ cấp.
  static String adminTimesheetById(String id) => '/admin/timesheets/$id';

  /// POST /admin/timesheets/{id}/approve → Duyệt hoặc từ chối bảng công tháng.
  static String approveAdminTimesheet(String id) =>
      '/admin/timesheets/$id/approve';

  /// GET /admin/stores/revenue → Thống kê doanh thu các cửa hàng đang hoạt động (Trang chủ Admin).
  static const String adminStoresRevenue = '/admin/stores/revenue';

  /// GET /admin/attendance → Danh sách chấm công nhân viên theo từng cơ sở.
  static const String adminAttendance = '/admin/attendance';

  /// POST /admin/attendance/status → Đánh dấu nhân viên Đang đi làm / Không đi làm & cập nhật ngày công.
  static const String adminAttendanceStatus = '/admin/attendance/status';

  /// PATCH /admin/attendance/work-days → Quản lý / chỉnh sửa số ngày công nhân viên đã chấm công.
  static const String adminAttendanceWorkDays = '/admin/attendance/work-days';

  /// GET / PUT /staff/profile → Xem & chỉnh sửa hồ sơ nhân viên đang đăng nhập.
  static const String staffProfile = '/staff/profile';

  /// POST /staff/profile/change-password → Đổi mật khẩu tài khoản nhân viên.
  static const String staffChangePassword = '/staff/profile/change-password';
}
