import 'package:flutter/foundation.dart';

import '../models/store_models.dart';
import '../services/staff_service.dart';

/// mô tả một kệ trưng bày cùng nhóm hàng và sức chứa tối đa.
class StaffShelf {
  const StaffShelf({
    required this.code,
    required this.category,
    required this.capacity,
  });

  final String code;
  final String category;
  final int capacity;
}

/// lưu dữ liệu hóa đơn nhân viên sau khi hoàn tất một lượt bán.
class StaffSale {
  const StaffSale({
    required this.invoiceNumber,
    required this.createdAt,
    required this.lines,
    required this.total,
  });

  final String invoiceNumber;
  final DateTime createdAt;
  final List<CartLine> lines;
  final int total;
}

/// ghi lại một lần hàng được tiếp nhận vào kho cùng số lượng và thời điểm.
class StaffStockReceipt {
  const StaffStockReceipt({
    required this.productId,
    required this.receivedAt,
    required this.quantity,
  });

  final String productId;
  final DateTime receivedAt;
  final int quantity;
}

/// xác định kệ và tầng hiện đang chứa một sản phẩm.
class StaffProductLocation {
  const StaffProductLocation({
    required this.shelfCode,
    required this.tier,
  });

  final String shelfCode;
  final int tier;
}

/// quản lý tồn kho, số lượng trên kệ và hóa đơn bán hàng tại máy nhân viên.
class StaffController extends ChangeNotifier {
  StaffController({required List<Product> products, StaffService? staffService})
    : _products = List<Product>.of(products),
      _staffService = staffService ?? StaffService(),
      _warehouseQuantities = {
        'milk': 24,
        'apple': 18,
        'eggs': 20,
        'rice': 12,
        'water': 36,
        'beef': 8,
      },
      _shelfQuantities = {
        'A1': {
          1: {'milk': 24},
          2: {'eggs': 5},
        },
        'A2': {
          1: {'water': 18},
        },
        'A3': {
          1: {'rice': 8},
        },
        'B1': {
          1: {'beef': 8},
        },
        'B2': {
          1: {'eggs': 15},
        },
        'B3': {
          1: {'milk': 8},
        },
        'C1': {
          1: {'beef': 6},
        },
        'C2': {
          1: {'rice': 5},
        },
        'C3': {
          1: {'apple': 16},
        },
      } {
    final receivedAt = DateTime.now();
    _stockReceipts.addAll(
      _warehouseQuantities.entries.map(
        (entry) => StaffStockReceipt(
          productId: entry.key,
          receivedAt: receivedAt,
          quantity: entry.value,
        ),
      ),
    );
  }

  List<Product> _products;
  final StaffService _staffService;
  final Map<String, int> _warehouseQuantities;
  final Map<String, Map<int, Map<String, int>>> _shelfQuantities;
  final List<StaffStockReceipt> _stockReceipts = [];
  final List<StaffSale> _sales = [];
  final Map<String, int> _saleCart = {};
  int _invoiceCounter = 1;
  int _intakeCount = 0;

  List<Product> get products => List.unmodifiable(_products);

  /// Cập nhật danh sách sản phẩm khi nạp lại từ backend.
  void updateProducts(List<Product> newProducts) {
    if (newProducts.isNotEmpty) {
      _products = List<Product>.of(newProducts);
      notifyListeners();
    }
  }

  /// Nạp thông tin kệ và tồn kho từ backend Java.
  Future<void> loadFromApi() async {
    try {
      final warehouseData = await _staffService.getWarehouse();
      if (warehouseData is List) {
        for (final item in warehouseData) {
          if (item is Map && item['productId'] != null) {
            final pId = item['productId'].toString();
            final qty = (item['quantity'] as num?)?.toInt() ?? 0;
            _warehouseQuantities[pId] = qty;
          }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Chưa lấy được dữ liệu kho từ API: $e');
    }
  }

  static const barcodeByProductId = <String, String>{
    'milk': '8938501001001',
    'apple': '8938501001002',
    'eggs': '8938501001003',
    'rice': '8938501001004',
    'water': '8938501001005',
    'beef': '8938501001006',
  };
  static const shelfTierCount = 4;
  static const lowStockThreshold = 5;

  static const shelfList = <StaffShelf>[
    StaffShelf(code: 'A1', category: 'Sữa & chế phẩm', capacity: 120),
    StaffShelf(code: 'A2', category: 'Nước giải khát', capacity: 100),
    StaffShelf(code: 'A3', category: 'Bánh kẹo', capacity: 100),
    StaffShelf(code: 'B1', category: 'Gia vị', capacity: 80),
    StaffShelf(code: 'B2', category: 'Đồ khô', capacity: 100),
    StaffShelf(code: 'B3', category: 'Chăm sóc nhà', capacity: 80),
    StaffShelf(code: 'C1', category: 'Thực phẩm lạnh', capacity: 80),
    StaffShelf(code: 'C2', category: 'Hàng mới về', capacity: 80),
    StaffShelf(code: 'C3', category: 'Kho dự trữ', capacity: 100),
  ];

  /// trả về hóa đơn ở dạng chỉ đọc để màn hình không sửa trực tiếp dữ liệu.
  List<StaffSale> get sales => List.unmodifiable(_sales);
  /// cho biết số lượt nhập kho đã ghi nhận trong phiên hiện tại.
  int get intakeCount => _intakeCount;
  /// cộng số lượng sản phẩm đang nằm trong kho dự trữ.
  int get warehouseItemCount => _warehouseQuantities.values.fold(
    0,
    (sum, quantity) => sum + quantity,
  );
  /// cộng số lượng sản phẩm đang được trưng bày trên tất cả các kệ.
  int get shelfItemCount => _shelfQuantities.values.fold(
    0,
    (sum, shelf) => sum + shelf.values.fold(
      0,
      (shelfSum, tier) =>
          shelfSum + tier.values.fold(0, (tierSum, count) => tierSum + count),
    ),
  );
  /// trả số hóa đơn đã hoàn tất trong phiên hiện tại.
  int get saleCount => _sales.length;
  /// trả lịch sử các lần nhập kho để xem ngày tiếp nhận hàng.
  List<StaffStockReceipt> get stockReceipts =>
      List.unmodifiable(_stockReceipts);

  /// dựng các dòng hàng từ giỏ bán hiện tại để hiển thị hóa đơn nháp.
  List<CartLine> get saleLines => _saleCart.entries
      .where((entry) => entry.value > 0)
      .map(
        (entry) => CartLine(
          product: productById(entry.key),
          quantity: entry.value,
        ),
      )
      .toList(growable: false);

  /// tính tổng tiền của các dòng hàng đang có trong hóa đơn nháp.
  int get saleTotal => saleLines.fold(0, (sum, line) => sum + line.total);

  /// tìm sản phẩm theo mã vạch khai báo hoặc mã định danh.
  Product? productFromBarcode(String barcode) {
    final normalized = barcode.trim();
    for (final product in products) {
      if (product.barcode == normalized ||
          barcodeByProductId[product.id] == normalized ||
          product.id == normalized) {
        return product;
      }
    }
    return null;
  }

  /// tìm sản phẩm theo mã định danh và báo lỗi nếu không tìm thấy.
  Product productById(String id) =>
      products.firstWhere((product) => product.id == id);

  /// trả số lượng của một sản phẩm đang còn trong kho dự trữ.
  int warehouseQuantity(String productId) =>
      _warehouseQuantities[productId] ?? 0;

  /// gộp nội dung bốn tầng của một kệ thành bản đồ chỉ đọc.
  Map<String, int> shelfContents(String shelfCode) {
    return Map.unmodifiable({
      for (final line in shelfLines(shelfCode)) line.product.id: line.quantity,
    });
  }

  /// trả nội dung sản phẩm và số lượng của một tầng kệ dưới dạng chỉ đọc.
  Map<String, int> shelfTierContents(String shelfCode, int tier) {
    _requireKnownTier(tier);
    return Map.unmodifiable(
      _shelfQuantities[shelfCode]?[tier] ?? const <String, int>{},
    );
  }

  /// chuyển hàng tại một tầng thành danh sách sản phẩm để hiển thị.
  List<CartLine> shelfTierLines(String shelfCode, int tier) {
    final contents = shelfTierContents(shelfCode, tier);
    return contents.entries
        .where((entry) => entry.value > 0)
        .map(
          (entry) => CartLine(
            product: productById(entry.key),
            quantity: entry.value,
          ),
        )
        .toList(growable: false);
  }

  /// gộp sản phẩm ở bốn tầng thành danh sách để tính tổng trên kệ.
  List<CartLine> shelfLines(String shelfCode) {
    final totals = <String, int>{};
    for (final tier in _shelfQuantities[shelfCode]?.values ??
        const <Map<String, int>>[]) {
      for (final entry in tier.entries) {
        totals.update(entry.key, (value) => value + entry.value,
            ifAbsent: () => entry.value);
      }
    }
    return totals.entries
        .where((entry) => entry.value > 0)
        .map(
          (entry) => CartLine(
            product: productById(entry.key),
            quantity: entry.value,
          ),
        )
        .toList(growable: false);
  }

  /// trả số lượng của một sản phẩm tại một kệ cụ thể.
  int shelfQuantity(String shelfCode, String productId) {
    return (_shelfQuantities[shelfCode]?.values ?? const <Map<String, int>>[])
        .fold(0, (sum, tier) => sum + (tier[productId] ?? 0));
  }

  /// trả số lượng của một sản phẩm tại một tầng cụ thể.
  int shelfTierQuantity(String shelfCode, int tier, String productId) =>
      _shelfQuantities[shelfCode]?[tier]?[productId] ?? 0;

  /// tìm vị trí đầu tiên đang trưng bày một sản phẩm.
  StaffProductLocation? locationForProduct(String productId) {
    final locations = locationsForProduct(productId);
    return locations.isEmpty ? null : locations.first;
  }

  /// tìm mọi kệ và tầng đang trưng bày cùng một sản phẩm.
  List<StaffProductLocation> locationsForProduct(String productId) {
    final locations = <StaffProductLocation>[];
    for (final shelf in shelfList) {
      final tiers = _shelfQuantities[shelf.code]!;
      for (var tier = 1; tier <= shelfTierCount; tier++) {
        if ((tiers[tier]?[productId] ?? 0) > 0) {
          locations.add(StaffProductLocation(shelfCode: shelf.code, tier: tier));
        }
      }
    }
    return List.unmodifiable(locations);
  }

  /// trả các dòng hàng có số lượng thấp hơn ngưỡng cảnh báo trên kệ.
  List<CartLine> lowStockLines(String shelfCode) {
    final lowStock = <String, int>{};
    final tiers = _shelfQuantities[shelfCode] ?? const <int, Map<String, int>>{};
    for (final tier in tiers.values) {
      for (final entry in tier.entries) {
        if (entry.value > 0 && entry.value < lowStockThreshold) {
          lowStock.update(entry.key, (value) => value + entry.value,
              ifAbsent: () => entry.value);
        }
      }
    }
    return lowStock.entries
        .map(
          (entry) => CartLine(
            product: productById(entry.key),
            quantity: entry.value,
          ),
        )
        .toList(growable: false);
  }

  /// lọc lịch sử nhập kho theo mã sản phẩm.
  List<StaffStockReceipt> receiptsForProduct(String productId) =>
      _stockReceipts
          .where((receipt) => receipt.productId == productId)
          .toList(growable: false);

  /// tính tỷ lệ lấp đầy của kệ so với sức chứa và giới hạn từ không đến một trăm.
  int getShelfFillPercent(String shelfCode) {
    final shelf = shelfList.firstWhere((item) => item.code == shelfCode);
    final occupied = shelfLines(shelfCode).fold<int>(
      0,
      (sum, line) => sum + line.quantity,
    );
    return (occupied * 100 / shelf.capacity).round().clamp(0, 100);
  }

  /// ghi nhận hàng mới vào kho và tăng số lượt nhập.
  void receiveStock(Product product, int quantity) {
    _requirePositiveQuantity(quantity);
    _warehouseQuantities.update(
      product.id,
      (current) => current + quantity,
      ifAbsent: () => quantity,
    );
    _stockReceipts.add(
      StaffStockReceipt(
        productId: product.id,
        receivedAt: DateTime.now(),
        quantity: quantity,
      ),
    );
    _intakeCount++;
    _staffService.receiveStock(productId: product.id, quantity: quantity).catchError((e) {
      debugPrint('Đồng bộ nhập kho lên API thất bại: $e');
    });
    notifyListeners();
  }

  /// chuyển hàng từ kho dự trữ lên kệ sau khi kiểm tra mã kệ và số lượng.
  void moveToShelf({
    required String shelfCode,
    required int tier,
    required Product product,
    required int quantity,
  }) {
    _requireKnownShelf(shelfCode);
    _requireKnownTier(tier);
    _requirePositiveQuantity(quantity);
    final inWarehouse = warehouseQuantity(product.id);
    if (quantity > inWarehouse) {
      throw StateError('Kho chỉ còn $inWarehouse sản phẩm này.');
    }
    final shelf = _shelfQuantities[shelfCode] ?? const <int, Map<String, int>>{};
    final currentTier = shelf[tier] ?? const <String, int>{};
    final differentProduct = currentTier.entries
        .where((entry) => entry.value > 0)
        .any((entry) => entry.key != product.id);
    if (differentProduct) {
      throw StateError('Tầng $tier của kệ $shelfCode đã chứa sản phẩm khác.');
    }
    _warehouseQuantities[product.id] = inWarehouse - quantity;
    final tierContents = _shelfQuantities
        .putIfAbsent(shelfCode, () => {})
        .putIfAbsent(tier, () => {});
    tierContents.update(
      product.id,
      (current) => current + quantity,
      ifAbsent: () => quantity,
    );
    _staffService.moveToShelf(
      shelfCode: shelfCode,
      tier: tier,
      productId: product.id,
      quantity: quantity,
    ).catchError((e) {
      debugPrint('Đồng bộ chuyển kệ lên API thất bại: $e');
    });
    notifyListeners();
  }

  /// thêm sản phẩm quét được vào hóa đơn nháp nếu trên kệ còn đủ hàng.
  void addSaleByBarcode(String barcode, {int quantity = 1}) {
    _requirePositiveQuantity(quantity);
    final product = productFromBarcode(barcode);
    if (product == null) {
      throw FormatException('Không tìm thấy sản phẩm có mã "$barcode".');
    }
    final available = shelfList.fold<int>(
      0,
      (sum, shelf) => sum + shelfQuantity(shelf.code, product.id),
    );
    final alreadyInBill = _saleCart[product.id] ?? 0;
    if (alreadyInBill + quantity > available) {
      throw StateError(
        'Trên kệ chỉ còn $available ${product.name.toLowerCase()}.',
      );
    }
    _saleCart.update(
      product.id,
      (current) => current + quantity,
      ifAbsent: () => quantity,
    );
    notifyListeners();
  }

  /// thay đổi số lượng trong hóa đơn nháp, đồng thời không cho vượt tồn trên kệ.
  void setSaleQuantity(Product product, int quantity) {
    if (quantity <= 0) {
      _saleCart.remove(product.id);
    } else {
      final available = shelfList.fold<int>(
        0,
        (sum, shelf) => sum + shelfQuantity(shelf.code, product.id),
      );
      if (quantity > available) {
        throw StateError('Trên kệ chỉ còn $available sản phẩm.');
      }
      _saleCart[product.id] = quantity;
    }
    notifyListeners();
  }

  /// trừ hàng trên các kệ, lưu hóa đơn hoàn tất và xóa hóa đơn nháp.
  StaffSale completeSale() {
    final lines = saleLines;
    if (lines.isEmpty) {
      throw StateError('Quét ít nhất một sản phẩm trước khi xuất hóa đơn.');
    }
    for (final line in lines) {
      final available = shelfList.fold<int>(
        0,
        (sum, shelf) => sum + shelfQuantity(shelf.code, line.product.id),
      );
      if (line.quantity > available) {
        throw StateError(
          'Không đủ ${line.product.name} trên kệ để hoàn tất hóa đơn.',
        );
      }
    }

    for (final line in lines) {
      var remaining = line.quantity;
      for (final shelf in shelfList) {
        final tiers = _shelfQuantities[shelf.code]!;
        for (var tier = 1; tier <= shelfTierCount; tier++) {
          final current = tiers[tier]?[line.product.id] ?? 0;
          if (current == 0) continue;
          final removed = current < remaining ? current : remaining;
          tiers[tier]![line.product.id] = current - removed;
          remaining -= removed;
          if (remaining == 0) break;
        }
        if (remaining == 0) {
          break;
        }
      }
    }
    final now = DateTime.now();
    final sale = StaffSale(
      invoiceNumber:
          'SSM-${now.year}${now.month.toString().padLeft(2, '0')}-'
          '${_invoiceCounter.toString().padLeft(4, '0')}',
      createdAt: now,
      lines: List.unmodifiable(lines),
      total: lines.fold(0, (sum, line) => sum + line.total),
    );
    _invoiceCounter++;
    _sales.insert(0, sale);

    _staffService.completeSale(
      lines: lines.map((l) => {
        'productId': l.product.id,
        'quantity': l.quantity,
        'price': l.product.price,
      }).toList(),
      total: sale.total,
    ).catchError((e) {
      debugPrint('Đồng bộ xuất hóa đơn POS lên API thất bại: $e');
    });

    _saleCart.clear();
    notifyListeners();
    return sale;
  }

  /// xóa các dòng của hóa đơn nháp mà không thay đổi lượng tồn.
  void clearSale() {
    _saleCart.clear();
    notifyListeners();
  }

  /// dừng thao tác khi số lượng nhập hoặc xuất không phải số dương.
  void _requirePositiveQuantity(int quantity) {
    if (quantity <= 0) {
      throw ArgumentError.value(quantity, 'quantity', 'Phải lớn hơn 0.');
    }
  }

  /// dừng thao tác nếu mã kệ không nằm trong danh sách kệ đã khai báo.
  void _requireKnownShelf(String shelfCode) {
    if (!shelfList.any((shelf) => shelf.code == shelfCode)) {
      throw ArgumentError.value(shelfCode, 'shelfCode', 'Kệ không tồn tại.');
    }
  }

  /// dừng thao tác nếu tầng được chọn nằm ngoài khoảng một đến bốn.
  void _requireKnownTier(int tier) {
    if (tier < 1 || tier > shelfTierCount) {
      throw ArgumentError.value(tier, 'tier', 'Tầng kệ phải từ 1 đến 4.');
    }
  }
}
