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
  });

  final String productId;
  final int requestedQuantity;
  final int? approvedQuantity;
  final String? productName;
  final String? productImage;
  final String? productBarcode;

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
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantity': requestedQuantity,
    'requestedQuantity': requestedQuantity,
    if (approvedQuantity != null) 'approvedQuantity': approvedQuantity,
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
    this.approvedBy,
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
  final String? approvedBy;
  final String? note;
  final String? rejectReason;
  final List<RestockRequestItem> items;
  final String? exportId;
  final String? exportStatus; // 'shipping', 'delivered'
  final int? itemCount;

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
      createdBy: (json['createdBy'] ?? json['created_by'])?.toString(),
      approvedBy: (json['approvedBy'] ?? json['approved_by'])?.toString(),
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
