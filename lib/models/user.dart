/// Mô hình User và phân quyền người dùng (chuyển đổi từ/sang JSON).
library;

import 'store_models.dart' show UserRole;

export 'store_models.dart' show UserRole;

/// Đại diện cho đối tượng Người dùng (User) trong hệ thống.
class User {
  const User({
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

  /// Kiểm tra tài khoản có phải nhân viên bán hàng không.
  bool get isSalesStaff => role == UserRole.salesStaff;

  /// Kiểm tra tài khoản có phải nhân viên kho không.
  bool get isWarehouseStaff => role == UserRole.warehouseStaff;

  /// Kiểm tra tài khoản có phải nhân viên nói chung không.
  bool get isStaff =>
      role == UserRole.staff ||
      role == UserRole.salesStaff ||
      role == UserRole.warehouseStaff;

  /// Kiểm tra tài khoản là khách hàng thông thường.
  bool get isCustomer => role == UserRole.customer;

  /// Chuyển đổi từ đối tượng JSON (API response) thành đối tượng [User].
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _pick(json, ['id', 'userId', 'staffId'])?.toString() ?? '',
      name: _pick(json, ['name', 'fullName', 'userName'])?.toString() ?? '',
      email: _pick(json, ['email', 'account', 'username'])?.toString() ?? '',
      phone: _pick(json, ['phone', 'phoneNumber'])?.toString(),
      role: UserRole.fromString(_pick(json, ['role', 'userRole'])?.toString()),
    );
  }

  /// Chuyển đối tượng [User] thành Map JSON để gửi lên API.
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

  /// Lấy giá trị đầu tiên khác null theo danh sách khóa JSON.
  static dynamic _pick(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json[key] != null) return json[key];
    }
    return null;
  }
}
