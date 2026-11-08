import 'product.dart';

/// Lưu thông tin một sản phẩm tồn trên kệ tại cửa hàng (bảng `store_stock`).
class StoreStockItem {
  const StoreStockItem({
    required this.product,
    required this.quantity,
    this.minQuantity = 5,
  });

  final Product product;
  final int quantity;
  final int minQuantity;

  bool get isLowStock => quantity <= minQuantity;
  bool get isOutOfStock => quantity <= 0;

  factory StoreStockItem.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> pJson = json['product'] is Map
        ? Map<String, dynamic>.from(json['product'] as Map)
        : json;

    final qty =
        _toInt(
          json['storeStockQuantity'] ??
              json['store_stock_quantity'] ??
              json['quantity'] ??
              json['stock'] ??
              json['storeQuantity'] ??
              pJson['storeStockQuantity'] ??
              pJson['store_stock_quantity'] ??
              pJson['stock'],
        ) ??
        0;
    final minQty = _toInt(json['minQuantity'] ?? json['min_quantity']) ?? 5;

    final baseProduct = Product.fromJson(pJson);
    final productWithStoreStock = Product(
      id: baseProduct.id,
      name: baseProduct.name,
      price: baseProduct.price,
      rating: baseProduct.rating,
      category: baseProduct.category,
      imageUrl: baseProduct.imageUrl,
      oldPrice: baseProduct.oldPrice,
      importPrice: baseProduct.importPrice,
      barcode: baseProduct.barcode,
      brand: baseProduct.brand,
      packageSize: baseProduct.packageSize,
      description: baseProduct.description,
      stock: qty,
    );

    return StoreStockItem(
      product: productWithStoreStock,
      quantity: qty,
      minQuantity: minQty,
    );
  }

  static int? _toInt(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.round();
    return num.tryParse(val.toString())?.round();
  }
}

/// Dòng sản phẩm trong phiếu yêu cầu nhập hàng.
class RestockRequestItem {
  const RestockRequestItem({
    required this.productId,
    required this.requestedQuantity,
    this.approvedQuantity,
    this.productName,
    this.productImage,
    this.productBarcode,
    this.warehouseStock,
    this.packageSize,
  });

  final String productId;
  final int requestedQuantity;
  final int? approvedQuantity;
  final String? productName;
  final String? productImage;
  final String? productBarcode;
  final int? warehouseStock;
  final String? packageSize;

  String get displayUnit {
    if (packageSize != null && packageSize!.trim().isNotEmpty) {
      return packageSize!.trim();
    }
    return 'Chưa cập nhật';
  }

  factory RestockRequestItem.fromJson(Map<String, dynamic> json) {
    final pMap = json['product'] is Map ? json['product'] as Map : null;
    return RestockRequestItem(
      productId: (json['productId'] ?? json['product_id'] ?? pMap?['id'] ?? '')
          .toString(),
      requestedQuantity:
          _toInt(
            json['requestedQuantity'] ??
                json['requested_quantity'] ??
                json['quantity'],
          ) ??
          0,
      approvedQuantity: _toInt(
        json['approvedQuantity'] ?? json['approved_quantity'],
      ),
      productName:
          (json['productName'] ?? json['product_name'] ?? pMap?['name'])
              ?.toString(),
      productImage:
          (json['imageUrl'] ??
                  json['productImage'] ??
                  pMap?['imageUrl'] ??
                  pMap?['image_url'])
              ?.toString(),
      productBarcode:
          (json['barcode'] ?? json['productBarcode'] ?? pMap?['barcode'])
              ?.toString(),
      warehouseStock: _toInt(
        json['warehouseStock'] ??
            json['warehouse_stock'] ??
            json['currentStock'] ??
            json['current_stock'] ??
            json['stock'] ??
            pMap?['warehouseStock'] ??
            pMap?['stock'],
      ),
      packageSize: (json['packageSize'] ??
              json['package_size'] ??
              json['unit'] ??
              json['productUnit'] ??
              json['product_unit'] ??
              pMap?['packageSize'] ??
              pMap?['package_size'] ??
              pMap?['unit'])
          ?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantity': requestedQuantity,
    'requestedQuantity': requestedQuantity,
    if (approvedQuantity != null) 'approvedQuantity': approvedQuantity,
    if (warehouseStock != null) 'warehouseStock': warehouseStock,
    if (packageSize != null) 'packageSize': packageSize,
  };

  static int? _toInt(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.round();
    return num.tryParse(val.toString())?.round();
  }
}

/// Lưu thông tin một phiếu yêu cầu xuất hàng từ kho cho cửa hàng (`restock_requests`).
class RestockRequest {
  const RestockRequest({
    required this.id,
    required this.storeId,
    required this.warehouseId,
    required this.status,
    required this.createdAt,
    this.storeName,
    this.warehouseName,
    this.createdBy,
    this.createdByName,
    this.approvedBy,
    this.approvedByName,
    this.exportedBy,
    this.exportedByName,
    this.receivedBy,
    this.receivedByName,
    this.note,
    this.rejectReason,
    this.items = const [],
    this.exportId,
    this.exportStatus,
    this.itemCount,
  });

  final String id;
  final String storeId;
  final String warehouseId;
  final String
  status; // 'pending', 'approved', 'rejected', 'exported', 'received'
  final DateTime createdAt;
  final String? storeName;
  final String? warehouseName;
  final String? createdBy;
  final String? createdByName;
  final String? approvedBy;
  final String? approvedByName;
  final String? exportedBy;
  final String? exportedByName;
  final String? receivedBy;
  final String? receivedByName;
  final String? note;
  final String? rejectReason;
  final List<RestockRequestItem> items;
  final String? exportId;
  final String? exportStatus; // 'shipping', 'delivered'
  final int? itemCount;

  String? get displayCreatedBy => _resolveName(createdByName, createdBy);
  String? get displayApprovedBy => _resolveName(approvedByName, approvedBy);
  String? get displayExportedBy => _resolveName(exportedByName, exportedBy);
  String? get displayReceivedBy => _resolveName(receivedByName, receivedBy);

  static String? _resolveName(String? name, String? fallback) {
    if (name != null && name.trim().isNotEmpty && !_isUuid(name)) {
      return name.trim();
    }
    if (fallback != null && fallback.trim().isNotEmpty && !_isUuid(fallback)) {
      return fallback.trim();
    }
    return null;
  }

  static bool _isUuid(String str) {
    final clean = str.trim();
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(clean);
  }

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isExported =>
      status.toLowerCase() == 'exported' || status.toLowerCase() == 'shipping';
  bool get isReceived =>
      status.toLowerCase() == 'received' || status.toLowerCase() == 'delivered';

  bool get isShipping =>
      exportStatus == 'shipping' ||
      status == 'exported' ||
      status == 'shipping';
  bool get canConfirmReceipt =>
      (status == 'exported' ||
          status == 'shipping' ||
          exportStatus == 'shipping') &&
      status != 'received' &&
      exportId != null &&
      exportId!.isNotEmpty;

  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Chờ duyệt';
      case 'approved':
        return 'Đã duyệt';
      case 'rejected':
        return 'Từ chối';
      case 'exported':
      case 'shipping':
        return 'Đang vận chuyển';
      case 'received':
      case 'delivered':
        return 'Đã nhận hàng';
      default:
        return status;
    }
  }

  factory RestockRequest.fromJson(Map<String, dynamic> json) {
    final rawItems =
        json['items'] ?? json['requestItems'] ?? json['restockRequestItems'];
    final itemsList = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map(
                (i) =>
                    RestockRequestItem.fromJson(Map<String, dynamic>.from(i)),
              )
              .toList()
        : <RestockRequestItem>[];

    final createdStr = json['createdAt'] ?? json['created_at'];
    final createdAt = createdStr != null
        ? (DateTime.tryParse(createdStr.toString()) ?? DateTime.now())
        : DateTime.now();

    final stockExportMap =
        json['stockExport'] is Map ? json['stockExport'] as Map : null;

    final createdByRaw = (json['createdBy'] ?? json['created_by'])?.toString();
    final createdByNameRaw = (json['createdByName'] ??
            json['created_by_name'] ??
            json['createdByFullName'] ??
            json['created_by_full_name'] ??
            json['creatorName'] ??
            json['creator']?['fullName'] ??
            json['creator']?['full_name'] ??
            json['creator']?['name'] ??
            json['created_by_employee']?['full_name'] ??
            json['created_by_employee']?['name'])
        ?.toString();

    final approvedByRaw =
        (json['approvedBy'] ?? json['approved_by'])?.toString();
    final approvedByNameRaw = (json['approvedByName'] ??
            json['approved_by_name'] ??
            json['approvedByFullName'] ??
            json['approved_by_full_name'] ??
            json['approverName'] ??
            json['approver']?['fullName'] ??
            json['approver']?['full_name'] ??
            json['approver']?['name'] ??
            json['approved_by_employee']?['full_name'] ??
            json['approved_by_employee']?['name'])
        ?.toString();

    final exportedByRaw = (json['exportedBy'] ??
            json['exported_by'] ??
            stockExportMap?['createdBy'] ??
            stockExportMap?['created_by'])
        ?.toString();
    final exportedByNameRaw = (json['exportedByName'] ??
            json['exported_by_name'] ??
            json['exportedByFullName'] ??
            json['exported_by_full_name'] ??
            json['exporterName'] ??
            stockExportMap?['createdByName'] ??
            stockExportMap?['created_by_name'] ??
            stockExportMap?['createdByFullName'] ??
            stockExportMap?['created_by_full_name'] ??
            stockExportMap?['creator']?['fullName'] ??
            stockExportMap?['creator']?['full_name'] ??
            stockExportMap?['creator']?['name'])
        ?.toString();

    final receivedByRaw = (json['receivedBy'] ??
            json['received_by'] ??
            stockExportMap?['receivedBy'] ??
            stockExportMap?['received_by'])
        ?.toString();
    final receivedByNameRaw = (json['receivedByName'] ??
            json['received_by_name'] ??
            json['receivedByFullName'] ??
            json['received_by_full_name'] ??
            json['receiverName'] ??
            stockExportMap?['receivedByName'] ??
            stockExportMap?['received_by_name'] ??
            stockExportMap?['receivedByFullName'] ??
            stockExportMap?['received_by_full_name'] ??
            stockExportMap?['receiver']?['fullName'] ??
            stockExportMap?['receiver']?['full_name'] ??
            stockExportMap?['receiver']?['name'])
        ?.toString();

    return RestockRequest(
      id: (json['id'] ?? json['requestId'] ?? '').toString(),
      storeId: (json['storeId'] ?? json['store_id'] ?? '').toString(),
      warehouseId: (json['warehouseId'] ?? json['warehouse_id'] ?? '')
          .toString(),
      status: (json['status'] ?? 'pending').toString().toLowerCase(),
      createdAt: createdAt,
      storeName:
          (json['storeName'] ?? json['store_name'] ?? json['store']?['name'])
              ?.toString(),
      warehouseName:
          (json['warehouseName'] ??
                  json['warehouse_name'] ??
                  json['warehouse']?['name'])
              ?.toString(),
      createdBy: createdByRaw,
      createdByName: createdByNameRaw,
      approvedBy: approvedByRaw,
      approvedByName: approvedByNameRaw,
      exportedBy: exportedByRaw,
      exportedByName: exportedByNameRaw,
      receivedBy: receivedByRaw,
      receivedByName: receivedByNameRaw,
      note: json['note']?.toString(),
      rejectReason: (json['rejectReason'] ?? json['reject_reason'])?.toString(),
      items: itemsList,
      exportId:
          (json['exportId'] ?? json['export_id'] ?? json['stockExport']?['id'])
              ?.toString(),
      exportStatus:
          (json['exportStatus'] ??
                  json['export_status'] ??
                  json['stockExport']?['status'])
              ?.toString()
              .toLowerCase(),
      itemCount: _toInt(json['itemCount'] ?? json['item_count']),
    );
  }

  static int? _toInt(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.round();
    return num.tryParse(val.toString())?.round();
  }
}
