class GoodsReceiptItem {
  const GoodsReceiptItem({
    required this.productId,
    this.productName,
    this.productBarcode,
    this.productImageUrl,
    this.packageSize,
    this.currentStock,
    required this.quantity,
    required this.importPrice,
    this.lotNo,
    this.expiryDate,
  });

  final String productId;
  final String? productName;
  final String? productBarcode;
  final String? productImageUrl;
  final String? packageSize;
  final int? currentStock;
  final int quantity;
  final int importPrice;
  final String? lotNo;
  final DateTime? expiryDate;

  int get subtotal => quantity * importPrice;

  String get displayUnit =>
      (packageSize != null && packageSize!.trim().isNotEmpty)
          ? packageSize!
          : 'Sản phẩm';

  factory GoodsReceiptItem.fromJson(Map<String, dynamic> json) {
    final prod =
        json['product'] is Map
            ? json['product'] as Map<String, dynamic>
            : null;

    return GoodsReceiptItem(
      productId:
          (json['productId'] ??
                  json['product_id'] ??
                  json['id'] ??
                  prod?['id'] ??
                  '')
              .toString(),
      productName:
          (json['productName'] ??
                  json['product_name'] ??
                  json['name'] ??
                  prod?['name'])
              ?.toString(),
      productBarcode:
          (json['productBarcode'] ??
                  json['product_barcode'] ??
                  json['barcode'] ??
                  prod?['barcode'])
              ?.toString(),
      productImageUrl:
          (json['productImageUrl'] ??
                  json['product_image_url'] ??
                  json['imageUrl'] ??
                  json['image_url'] ??
                  prod?['imageUrl'])
              ?.toString(),
      packageSize:
          (json['packageSize'] ??
                  json['package_size'] ??
                  json['unit'] ??
                  prod?['packageSize'] ??
                  prod?['package_size'])
              ?.toString(),
      currentStock: _toInt(
        json['currentStock'] ??
            json['current_stock'] ??
            json['stock'] ??
            json['warehouseStock'],
      ),
      quantity: _toInt(json['quantity'] ?? json['amount']) ?? 0,
      importPrice:
          _toInt(json['importPrice'] ?? json['import_price'] ?? json['price']) ??
          0,
      lotNo: (json['lotNo'] ?? json['lot_no'] ?? json['lotNumber'])?.toString(),
      expiryDate: _parseDate(json['expiryDate'] ?? json['expiry_date']),
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    if (productName != null) 'productName': productName,
    if (productBarcode != null) 'productBarcode': productBarcode,
    if (packageSize != null) 'packageSize': packageSize,
    'quantity': quantity,
    'importPrice': importPrice,
    if (lotNo != null && lotNo!.trim().isNotEmpty) 'lotNo': lotNo,
    if (expiryDate != null)
      'expiryDate': expiryDate!.toIso8601String().split('T').first,
  };

  static int? _toInt(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.round();
    return num.tryParse(val.toString())?.round();
  }

  static DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) return val;
    return DateTime.tryParse(val.toString());
  }
}

class GoodsReceipt {
  const GoodsReceipt({
    required this.id,
    required this.warehouseId,
    this.warehouseName,
    this.supplierId,
    this.supplierName,
    this.supplierPhone,
    this.supplierAddress,
    required this.createdBy,
    this.displayCreatedBy,
    required this.totalAmount,
    this.note,
    required this.status,
    required this.createdAt,
    this.completedAt,
    required this.items,
  });

  final String id;
  final String warehouseId;
  final String? warehouseName;
  final String? supplierId;
  final String? supplierName;
  final String? supplierPhone;
  final String? supplierAddress;
  final String createdBy;
  final String? displayCreatedBy;
  final int totalAmount;
  final String? note;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<GoodsReceiptItem> items;

  bool get isDraft => status.toLowerCase() == 'draft';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'draft':
        return 'Nháp';
      case 'completed':
        return 'Hoàn tất';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  String get creatorDisplay {
    final name = displayCreatedBy?.trim();
    if (name != null && name.isNotEmpty && !_isUuid(name)) {
      return name;
    }
    final by = createdBy.trim();
    if (by.isNotEmpty && !_isUuid(by)) {
      return by;
    }
    return 'Nhân viên lập phiếu';
  }

  static bool _isUuid(String str) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(str.trim());
  }

  int get calculatedTotal {
    if (items.isEmpty) return totalAmount;
    return items.fold<int>(0, (sum, item) => sum + item.subtotal);
  }

  int get totalQuantity {
    return items.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  factory GoodsReceipt.fromJson(Map<String, dynamic> json) {
    final supp = json['supplier'] is Map
        ? json['supplier'] as Map<String, dynamic>
        : null;
    final creator = json['creator'] is Map
        ? json['creator'] as Map<String, dynamic>
        : (json['employee'] is Map
            ? json['employee'] as Map<String, dynamic>
            : (json['user'] is Map
                ? json['user'] as Map<String, dynamic>
                : (json['created_by_employee'] is Map
                    ? json['created_by_employee'] as Map<String, dynamic>
                    : null)));
    final wh = json['warehouse'] is Map
        ? json['warehouse'] as Map<String, dynamic>
        : null;

    final rawItems =
        json['items'] ?? json['receiptItems'] ?? json['goods_receipt_items'];
    final itemList = <GoodsReceiptItem>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          itemList.add(
            GoodsReceiptItem.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final creatorName = (json['displayCreatedBy'] ??
            json['created_by_name'] ??
            json['createdByName'] ??
            json['createdByFullName'] ??
            json['created_by_full_name'] ??
            json['creatorName'] ??
            json['creator_name'] ??
            creator?['name'] ??
            creator?['fullName'] ??
            creator?['full_name'])
        ?.toString();

    return GoodsReceipt(
      id: (json['id'] ?? json['receiptId'] ?? json['code'] ?? '').toString(),
      warehouseId:
          (json['warehouseId'] ?? json['warehouse_id'] ?? wh?['id'] ?? '')
              .toString(),
      warehouseName:
          (json['warehouseName'] ?? json['warehouse_name'] ?? wh?['name'])
              ?.toString(),
      supplierId:
          (json['supplierId'] ?? json['supplier_id'] ?? supp?['id'])
              ?.toString(),
      supplierName:
          (json['supplierName'] ?? json['supplier_name'] ?? supp?['name'])
              ?.toString(),
      supplierPhone:
          (json['supplierPhone'] ?? json['supplier_phone'] ?? supp?['phone'])
              ?.toString(),
      supplierAddress:
          (json['supplierAddress'] ??
                  json['supplier_address'] ??
                  supp?['address'])
              ?.toString(),
      createdBy:
          (json['createdBy'] ?? json['created_by'] ?? creator?['id'] ?? '')
              .toString(),
      displayCreatedBy: creatorName,
      totalAmount:
          GoodsReceiptItem._toInt(
            json['totalAmount'] ?? json['total_amount'],
          ) ??
          0,
      note: json['note']?.toString(),
      status: (json['status'] ?? 'draft').toString().toLowerCase(),
      createdAt:
          GoodsReceiptItem._parseDate(
            json['createdAt'] ?? json['created_at'],
          ) ??
          DateTime.now(),
      completedAt: GoodsReceiptItem._parseDate(
        json['completedAt'] ?? json['completed_at'],
      ),
      items: itemList,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'warehouseId': warehouseId,
    if (supplierId != null) 'supplierId': supplierId,
    if (note != null) 'note': note,
    'status': status,
    'items': items.map((i) => i.toJson()).toList(),
  };
}
