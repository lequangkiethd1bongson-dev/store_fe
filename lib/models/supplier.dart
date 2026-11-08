class Supplier {
  const Supplier({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.email,
    this.fax,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? phone;
  final String? address;
  final String? email;
  final String? fax;
  final bool isActive;

  factory Supplier.fromJson(Map<String, dynamic> json) {
    final activeVal = json['isActive'] ?? json['is_active'] ?? json['active'];
    bool active = true;
    if (activeVal != null) {
      if (activeVal is bool) {
        active = activeVal;
      } else {
        final str = activeVal.toString().trim().toLowerCase();
        active = str == 'true' || str == '1' || str == 'active';
      }
    } else if (json['status'] != null) {
      active = json['status'].toString().trim().toLowerCase() == 'active';
    }

    return Supplier(
      id: (json['id'] ?? json['supplierId'] ?? json['supplier_id'] ?? '')
          .toString(),
      name:
          (json['name'] ?? json['supplierName'] ?? json['supplier_name'] ?? '')
              .toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      email: json['email']?.toString(),
      fax: json['fax']?.toString(),
      isActive: active,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (phone != null) 'phone': phone,
    if (address != null) 'address': address,
    if (email != null) 'email': email,
    if (fax != null) 'fax': fax,
    'isActive': isActive,
    'is_active': isActive,
  };
}
