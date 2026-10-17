/// lưu thông tin sản phẩm, dòng giỏ hàng và đơn mua trong ứng dụng.
///
/// class `Product` đã được chuyển sang `product.dart` (bước 3) để chỉ còn
/// một định nghĩa duy nhất; export lại ở đây để các màn hình cũ vẫn import
/// `store_models.dart` như trước.
library;

import 'product.dart';

export 'product.dart';

/// phân quyền tài khoản người dùng trong hệ thống.
enum UserRole {
  customer,
  salesStaff,
  warehouseStaff,
  staff;

  static UserRole fromString(String? role) {
    final clean = (role ?? '').toUpperCase();
    if (clean.contains('WAREHOUSE') || clean.contains('KHO')) {
      return UserRole.warehouseStaff;
    }
    if (clean.contains('SALES') || clean.contains('BAN_HANG') || clean.contains('BANHANG')) {
      return UserRole.salesStaff;
    }
    if (clean.contains('STAFF') || clean.contains('NHAN_VIEN')) {
      return UserRole.salesStaff;
    }
    return UserRole.customer;
  }
}

/// thông tin tài khoản sau khi đăng nhập thành công từ backend.
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role = UserRole.customer,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;

  /// kiểm tra người dùng có phải nhân viên bán hàng không.
  bool get isSalesStaff => role == UserRole.salesStaff;

  /// kiểm tra người dùng có phải nhân viên kho không.
  bool get isWarehouseStaff => role == UserRole.warehouseStaff;

  /// kiểm tra người dùng có phải nhân viên siêu thị không.
  bool get isStaff =>
      role == UserRole.staff ||
      role == UserRole.salesStaff ||
      role == UserRole.warehouseStaff;

  /// kiểm tra người dùng là khách hàng thông thường.
  bool get isCustomer => role == UserRole.customer;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      role: UserRole.fromString(json['role']?.toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role == UserRole.salesStaff
        ? 'SALES_STAFF'
        : role == UserRole.warehouseStaff
            ? 'WAREHOUSE_STAFF'
            : role == UserRole.staff
                ? 'STAFF'
                : 'CUSTOMER',
  };
}

/// biểu diễn một sản phẩm cùng số lượng đang có trong giỏ hoặc đơn hàng.
class CartLine {
  const CartLine({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  /// tính thành tiền của dòng hàng này.
  int get total => product.price * quantity;
}

/// lưu mã, thời điểm, các dòng sản phẩm và trạng thái của đơn mua.
class StoreOrder {
  const StoreOrder({
    required this.id,
    required this.createdAt,
    required this.lines,
    required this.total,
    this.status = 'Chờ xác nhận',
  });

  final String id;
  final DateTime createdAt;
  final List<CartLine> lines;
  final int total;
  final String status;
}

/// đổi số tiền nguyên sang chuỗi tiền việt có dấu phân cách hàng nghìn.
String formatVnd(int amount) {
  final digits = amount.abs().toString();
  final groups = <String>[];
  for (var end = digits.length; end > 0; end -= 3) {
    final start = end - 3 < 0 ? 0 : end - 3;
    groups.insert(0, digits.substring(start, end));
  }
  final sign = amount < 0 ? '−' : '';
  return '$sign${groups.join('.')}đ';
}
