class Supplier {
  const Supplier({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.fax,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String? fax;
  final bool isActive;

  factory Supplier.fromJson(Map<String, dynamic> json) {
    bool? active;

    // Kiểm tra chính xác các field trạng thái từ Backend (isActive, is_active, active, enabled)
    final candidates = [
      json['isActive'],
      json['is_active'],
      json['active'],
      json['enabled'],
    ];

    for (final val in candidates) {
      if (val != null) {
        if (val is bool) {
          active = val;
          break;
        } else if (val is num) {
          active = val != 0;
          break;
        } else if (val is String) {
          final s = val.trim().toLowerCase();
          if (s == 'true' || s == '1' || s == 'active' || s == 'enabled') {
            active = true;
            break;
          } else if (s == 'false' ||
              s == '0' ||
              s == 'inactive' ||
              s == 'disabled') {
            active = false;
            break;
          }
        }
      }
    }

    if (active == null && json['status'] != null) {
      final s = json['status'].toString().trim().toLowerCase();
      if (s == 'active' || s == 'enabled') {
        active = true;
      } else if (s == 'inactive' || s == 'disabled' || s == 'cancelled') {
        active = false;
      }
    }

    return Supplier(
      id: (json['id'] ?? json['supplierId'] ?? json['supplier_id'] ?? '')
          .toString(),
      name:
          (json['name'] ?? json['supplierName'] ?? json['supplier_name'] ?? '')
              .toString(),
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      fax: json['fax']?.toString(),
      isActive: active ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (address != null) 'address': address,
    if (phone != null) 'phone': phone,
    if (email != null) 'email': email,
    if (fax != null) 'fax': fax,
    'isActive': isActive,
  };

  Supplier copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? fax,
    bool? isActive,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      fax: fax ?? this.fax,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Supplier &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          address == other.address &&
          phone == other.phone &&
          email == other.email &&
          fax == other.fax &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      address.hashCode ^
      phone.hashCode ^
      email.hashCode ^
      fax.hashCode ^
      isActive.hashCode;
}
