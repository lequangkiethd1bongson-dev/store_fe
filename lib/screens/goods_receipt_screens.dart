import 'package:flutter/material.dart';

import '../core/network/api_client.dart';
import '../features/suppliers/screens/supplier_form_screen.dart';
import '../features/suppliers/screens/supplier_list_screen.dart';
import '../features/suppliers/state/supplier_controller.dart';
import '../models/goods_receipt_models.dart';
import '../models/product.dart';
import '../models/supplier.dart';
import '../services/auth_service.dart';
import '../services/goods_receipt_service.dart';
import '../services/product_service.dart';
import '../services/supplier_service.dart';
import '../theme/app_theme.dart';

/// Định dạng lỗi API theo chuẩn cho màn hình phiếu nhập kho
String formatGoodsReceiptApiError(Object e) {
  if (e is ApiException) {
    switch (e.statusCode) {
      case 400:
        return e.message.isNotEmpty
            ? e.message
            : 'Dữ liệu nhập không hợp lệ (400).';
      case 401:
        return 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại (401).';
      case 403:
        return 'Bạn không có quyền thực hiện hoặc không thuộc kho được phân công (403).';
      case 404:
        return 'Không tìm thấy phiếu nhập hoặc nhà cung cấp (404).';
      case 409:
        return e.message.isNotEmpty
            ? e.message
            : 'Trạng thái phiếu không cho phép chỉnh sửa/xác nhận (409).';
      case 500:
        return 'Lỗi máy chủ (500). Vui lòng thử lại sau.';
      default:
        return e.message;
    }
  }
  return e.toString().replaceFirst('ApiException: ', '');
}

/// Định dạng số tiền sang chuẩn VND (VD: 1.500.000đ)
String formatReceiptVnd(num amount) {
  final integerAmount = amount.round();
  final sign = integerAmount < 0 ? '-' : '';
  final absString = integerAmount.abs().toString();

  final buffer = StringBuffer();
  for (var i = 0; i < absString.length; i++) {
    if (i > 0 && (absString.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(absString[i]);
  }
  return '$sign${buffer.toString()}đ';
}

/// Kiểm tra role Admin
bool isAdminRole(String? role) {
  return (role ?? '').trim().toUpperCase() == 'ADMIN';
}

/// Kiểm tra role Nhân viên hoặc Quản lý kho
bool isWarehouseRole(String? role) {
  final clean = (role ?? '').trim().toUpperCase();
  return clean == 'WAREHOUSE_MANAGER' ||
      clean == 'KHO_MANAGER' ||
      clean == 'KHO_QUAN_LY' ||
      clean == 'QUAN_LY_KHO' ||
      clean == 'WAREHOUSE_STAFF' ||
      clean == 'KHO' ||
      clean == 'KHO_STAFF' ||
      clean == 'ADMIN';
}

/// Màn hình Danh sách Phiếu nhập hàng từ nhà cung cấp
class GoodsReceiptsScreen extends StatefulWidget {
  const GoodsReceiptsScreen({required this.userRole, super.key});

  final String userRole;

  @override
  State<GoodsReceiptsScreen> createState() => _GoodsReceiptsScreenState();
}

class _GoodsReceiptsScreenState extends State<GoodsReceiptsScreen> {
  final _receiptService = GoodsReceiptService();
  String _selectedStatus = 'ALL';
  String _searchQuery = '';
  List<GoodsReceipt> _receipts = [];
  bool _isLoading = true;
  String? _errorMessage;

  bool get _canAccess => isWarehouseRole(widget.userRole);

  static const _statusOptions = [
    {'value': 'ALL', 'label': 'Tất cả'},
    {'value': 'draft', 'label': 'Nháp'},
    {'value': 'completed', 'label': 'Hoàn tất'},
    {'value': 'cancelled', 'label': 'Đã hủy'},
  ];

  @override
  void initState() {
    super.initState();
    if (_canAccess) {
      _loadReceipts();
    }
  }

  @override
  void dispose() {
    _receiptService.dispose();
    super.dispose();
  }

  Future<void> _loadReceipts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _receiptService.getGoodsReceipts(
        status: _selectedStatus == 'ALL' ? null : _selectedStatus,
        search: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
      );
      if (!mounted) return;
      setState(() {
        _receipts = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = formatGoodsReceiptApiError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_canAccess) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nhập hàng từ nhà cung cấp')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gpp_bad_rounded, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Truy cập bị từ chối',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Chức năng nhập hàng từ nhà cung cấp chỉ dành cho khu vực Quản lý và Nhân viên Kho.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filteredList = _receipts.where((r) {
      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      final codeMatch = r.id.toLowerCase().contains(q);
      final supplierMatch = (r.supplierName ?? '').toLowerCase().contains(q);
      return codeMatch || supplierMatch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Nhập hàng từ nhà cung cấp'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _loadReceipts,
            icon: const Icon(Icons.refresh_rounded),
          ),
          if (isAdminRole(widget.userRole))
            IconButton(
              tooltip: 'Quản lý Nhà cung cấp',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        SupplierManagementScreen(userRole: widget.userRole),
                  ),
                );
              },
              icon: const Icon(Icons.business_rounded),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.blue700,
        onPressed: () async {
          final res = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) =>
                  CreateGoodsReceiptScreen(userRole: widget.userRole),
            ),
          );
          if (res == true) _loadReceipts();
        },
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'TẠO PHIẾU NHẬP',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Ô tìm kiếm & Bộ lọc
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                onChanged: (val) {
                  setState(() => _searchQuery = val);
                },
                decoration: const InputDecoration(
                  hintText: 'Tìm theo mã phiếu hoặc tên nhà cung cấp',
                  prefixIcon: Icon(Icons.search_rounded),
                  isDense: true,
                ),
              ),
            ),

            // Thanh chọn trạng thái
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: _statusOptions.map((opt) {
                  final isSel = _selectedStatus == opt['value'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(opt['label']!),
                      selected: isSel,
                      selectedColor: AppColors.blue700,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : AppColors.ink,
                        fontSize: 11,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedStatus = opt['value']!);
                          _loadReceipts();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadReceipts,
                child: _buildContent(filteredList),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<GoodsReceipt> filteredList) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.error_outline_rounded, size: 56, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.red),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: _loadReceipts,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ),
        ],
      );
    }

    if (filteredList.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: const [
          Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.muted),
          SizedBox(height: 16),
          Text(
            'Không tìm thấy phiếu nhập nào.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            'Bấm "Tạo phiếu nhập" bên dưới để khởi tạo phiếu nhập hàng mới từ nhà cung cấp.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final item = filteredList[index];
        return _GoodsReceiptCard(
          receipt: item,
          onTap: () async {
            final res = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => GoodsReceiptDetailScreen(
                  receiptId: item.id,
                  userRole: widget.userRole,
                  initialReceipt: item,
                ),
              ),
            );
            if (res == true) _loadReceipts();
          },
        );
      },
    );
  }
}

class _GoodsReceiptCard extends StatelessWidget {
  const _GoodsReceiptCard({required this.receipt, required this.onTap});

  final GoodsReceipt receipt;
  final VoidCallback onTap;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.orange[800]!;
      case 'completed':
        return Colors.green[700]!;
      case 'cancelled':
        return Colors.red[700]!;
      default:
        return AppColors.ink;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(receipt.status);
    final dateStr =
        '${receipt.createdAt.day.toString().padLeft(2, '0')}/${receipt.createdAt.month.toString().padLeft(2, '0')}/${receipt.createdAt.year} ${receipt.createdAt.hour.toString().padLeft(2, '0')}:${receipt.createdAt.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mã phiếu: ${receipt.id.length > 12 ? receipt.id.substring(0, 12) : receipt.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      receipt.statusDisplay,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.business_outlined,
                    size: 16,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'NCC: ${receipt.supplierName ?? receipt.supplierId ?? 'Chưa chọn'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.warehouse_outlined,
                    size: 16,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Kho: ${receipt.warehouseName ?? receipt.warehouseId}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.access_time_rounded,
                    size: 15,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 16,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Người lập: ${receipt.creatorDisplay}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${receipt.items.length} mặt hàng (${receipt.totalQuantity} SP)',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                  Text(
                    formatReceiptVnd(receipt.calculatedTotal),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.blue800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Màn hình Lập / Chỉnh sửa Phiếu nhập hàng từ Nhà cung cấp
class CreateGoodsReceiptScreen extends StatefulWidget {
  const CreateGoodsReceiptScreen({
    required this.userRole,
    this.initialReceipt,
    super.key,
  });

  final String userRole;
  final GoodsReceipt? initialReceipt;

  @override
  State<CreateGoodsReceiptScreen> createState() =>
      _CreateGoodsReceiptScreenState();
}

class _CreateGoodsReceiptScreenState extends State<CreateGoodsReceiptScreen> {
  final _goodsReceiptService = GoodsReceiptService();
  final _supplierService = SupplierService();
  final _productService = ProductService();
  final _authService = AuthService();

  final _noteController = TextEditingController();

  List<WarehouseOption> _warehouses = [];
  String? _selectedWarehouseId;
  String? _selectedWarehouseName;
  bool _isLoadingWarehouses = true;

  List<Supplier> _suppliers = [];
  String? _selectedSupplierId;
  bool _isLoadingSuppliers = true;

  List<Product> _allProducts = [];

  String? _creatorName;

  // Danh sách dòng sản phẩm đã chọn: Map đại diện cho thông tin chỉnh sửa
  final List<_GoodsReceiptItemEditModel> _selectedItems = [];

  bool _isSubmitting = false;

  bool get _isAdmin => isAdminRole(widget.userRole);

  @override
  void initState() {
    super.initState();
    if (widget.initialReceipt != null) {
      _noteController.text = widget.initialReceipt!.note ?? '';
      _selectedWarehouseId = widget.initialReceipt!.warehouseId;
      _selectedSupplierId = widget.initialReceipt!.supplierId;

      for (final item in widget.initialReceipt!.items) {
        _selectedItems.add(
          _GoodsReceiptItemEditModel(
            productId: item.productId,
            name: item.productName ?? 'Sản phẩm ${item.productId}',
            barcode: item.productBarcode,
            unit: item.displayUnit,
            currentStock: item.currentStock ?? 0,
            quantity: item.quantity,
            importPrice: item.importPrice,
            lotNo: item.lotNo ?? '',
            expiryDate: item.expiryDate,
          ),
        );
      }
    }

    _loadInitialData();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _goodsReceiptService.dispose();
    _supplierService.dispose();
    _productService.dispose();
    _authService.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadProfileAndWarehouse(),
      _loadSuppliers(),
      _loadProducts(),
    ]);
  }

  Future<void> _loadProfileAndWarehouse() async {
    try {
      final warehouses = await _productService.getWarehouses();
      Map<String, dynamic>? profile;
      try {
        profile = await _authService.getMe();
      } catch (_) {}

      if (!mounted) return;

      setState(() {
        _warehouses = warehouses;
        _creatorName =
            profile?['name']?.toString() ?? profile?['fullName']?.toString();

        final empWhId =
            profile?['warehouseId']?.toString() ??
            profile?['warehouse_id']?.toString();

        if (widget.initialReceipt != null) {
          _selectedWarehouseId = widget.initialReceipt!.warehouseId;
        } else if (!_isAdmin && empWhId != null && empWhId.isNotEmpty) {
          _selectedWarehouseId = empWhId;
        } else if (warehouses.isNotEmpty) {
          _selectedWarehouseId = warehouses.first.id;
        }

        final matchedWh = warehouses.firstWhere(
          (w) => w.id == _selectedWarehouseId,
          orElse: () => warehouses.isNotEmpty
              ? warehouses.first
              : const WarehouseOption(id: '', name: 'Kho mặc định'),
        );
        _selectedWarehouseName = matchedWh.name;

        _isLoadingWarehouses = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingWarehouses = false);
    }
  }

  Supplier? get _selectedSupplier {
    if (_selectedSupplierId == null) return null;
    try {
      return _suppliers.firstWhere((s) => s.id == _selectedSupplierId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _openSupplierPicker() async {
    final supp = await showModalBottomSheet<Supplier>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _SupplierPickerSheet(
        suppliers: _suppliers,
        selectedSupplierId: _selectedSupplierId,
        userRole: widget.userRole,
        onSupplierAdded: (newSupp) {
          setState(() {
            _suppliers.insert(0, newSupp);
            _selectedSupplierId = newSupp.id;
          });
        },
      ),
    );
    if (supp != null) {
      setState(() {
        _selectedSupplierId = supp.id;
      });
    }
  }

  Future<void> _loadSuppliers() async {
    try {
      final suppliers = await _supplierService.getSuppliers(activeOnly: true);
      if (!mounted) return;
      setState(() {
        _suppliers = suppliers;
        if (_selectedSupplierId == null && suppliers.isNotEmpty) {
          _selectedSupplierId = suppliers.first.id;
        }
        _isLoadingSuppliers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingSuppliers = false);
    }
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _productService.getProducts();
      if (!mounted) return;
      setState(() {
        _allProducts = products;
      });
    } catch (_) {}
  }

  int get _totalAmountCalculated {
    return _selectedItems.fold<int>(0, (sum, item) => sum + item.subtotal);
  }

  void _onAddProductSelected(Product product) {
    // Kiểm tra không cho trùng sản phẩm
    final existingIndex = _selectedItems.indexWhere(
      (item) => item.productId == product.id,
    );
    if (existingIndex != -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sản phẩm "${product.name}" đã có trong phiếu nhập! Đã chuyển đến dòng sản phẩm thứ ${existingIndex + 1}.',
          ),
          backgroundColor: Colors.orange[800],
        ),
      );
      return;
    }

    setState(() {
      _selectedItems.add(
        _GoodsReceiptItemEditModel(
          productId: product.id,
          name: product.name,
          barcode: product.barcode,
          unit:
              (product.packageSize != null &&
                  product.packageSize!.trim().isNotEmpty)
              ? product.packageSize!
              : 'Sản phẩm',
          currentStock: product.stock,
          quantity: 1,
          importPrice: product.importPrice ?? product.price,
          lotNo: '',
        ),
      );
    });
  }

  bool _validateInput() {
    if (_selectedWarehouseId == null || _selectedWarehouseId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn Kho nhập hàng.')),
      );
      return false;
    }

    if (_selectedSupplierId == null || _selectedSupplierId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn Nhà cung cấp.')),
      );
      return false;
    }

    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Danh sách sản phẩm nhập không được rỗng. Vui lòng bấm "Thêm sản phẩm".',
          ),
        ),
      );
      return false;
    }

    for (final item in _selectedItems) {
      if (item.quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Số lượng của sản phẩm "${item.name}" phải là số nguyên dương (> 0).',
            ),
          ),
        );
        return false;
      }
      if (item.importPrice <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đơn giá nhập của sản phẩm "${item.name}" phải lớn hơn 0.',
            ),
          ),
        );
        return false;
      }
    }

    return true;
  }

  Future<void> _saveDraft() async {
    if (!_validateInput()) return;

    setState(() => _isSubmitting = true);

    final itemsPayload = _selectedItems.map((item) {
      return {
        'productId': item.productId,
        'quantity': item.quantity,
        'importPrice': item.importPrice,
        if (item.lotNo.trim().isNotEmpty) 'lotNo': item.lotNo.trim(),
        if (item.expiryDate != null)
          'expiryDate': item.expiryDate!.toIso8601String().split('T').first,
      };
    }).toList();

    try {
      GoodsReceipt result;
      if (widget.initialReceipt != null) {
        result = await _goodsReceiptService.updateDraftReceipt(
          receiptId: widget.initialReceipt!.id,
          warehouseId: _selectedWarehouseId,
          supplierId: _selectedSupplierId,
          note: _noteController.text,
          items: itemsPayload,
        );
      } else {
        result = await _goodsReceiptService.createDraftReceipt(
          warehouseId: _selectedWarehouseId!,
          supplierId: _selectedSupplierId!,
          note: _noteController.text,
          items: itemsPayload,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Đã lưu nháp phiếu nhập hàng thành công! (Tồn kho chưa bị thay đổi)',
          ),
          backgroundColor: Colors.green[700],
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GoodsReceiptDetailScreen(
            receiptId: result.id,
            userRole: widget.userRole,
            initialReceipt: result,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lưu nháp thất bại: ${formatGoodsReceiptApiError(e)}'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  Future<void> _submitConfirmReceipt() async {
    if (!_validateInput()) return;

    final supplier = _suppliers.firstWhere(
      (s) => s.id == _selectedSupplierId,
      orElse: () =>
          Supplier(id: _selectedSupplierId ?? '', name: 'Nhà cung cấp đã chọn'),
    );

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận hoàn tất nhập kho'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thao tác này sẽ thực sự đưa hàng vào kho và cập nhật giá nhập mới nhất. Bạn có chắc chắn?',
            ),
            const SizedBox(height: 12),
            Text(
              '• Nhà cung cấp: ${supplier.name}\n'
              '• Kho nhận: ${_selectedWarehouseName ?? _selectedWarehouseId}\n'
              '• Số mặt hàng: ${_selectedItems.length}\n'
              '• Tổng tiền nhập: ${formatReceiptVnd(_totalAmountCalculated)}',
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue700),
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
            label: const Text(
              'XÁC NHẬN NHẬP KHO',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    final itemsPayload = _selectedItems.map((item) {
      return {
        'productId': item.productId,
        'quantity': item.quantity,
        'importPrice': item.importPrice,
        if (item.lotNo.trim().isNotEmpty) 'lotNo': item.lotNo.trim(),
        if (item.expiryDate != null)
          'expiryDate': item.expiryDate!.toIso8601String().split('T').first,
      };
    }).toList();

    try {
      GoodsReceipt draft;
      if (widget.initialReceipt != null) {
        draft = await _goodsReceiptService.updateDraftReceipt(
          receiptId: widget.initialReceipt!.id,
          warehouseId: _selectedWarehouseId,
          supplierId: _selectedSupplierId,
          note: _noteController.text,
          items: itemsPayload,
        );
      } else {
        draft = await _goodsReceiptService.createDraftReceipt(
          warehouseId: _selectedWarehouseId!,
          supplierId: _selectedSupplierId!,
          note: _noteController.text,
          items: itemsPayload,
        );
      }

      // Tiếp theo gọi API hoàn tất
      final completed = await _goodsReceiptService.completeGoodsReceipt(
        draft.id,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Nhập kho thành công! Tồn kho và giá nhập gần nhất đã được cập nhật.',
          ),
          backgroundColor: Colors.green[700],
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GoodsReceiptDetailScreen(
            receiptId: completed.id,
            userRole: widget.userRole,
            initialReceipt: completed,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nhập kho thất bại: ${formatGoodsReceiptApiError(e)}'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isWarehouseRole(widget.userRole)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tạo phiếu nhập')),
        body: const Center(child: Text('Truy cập bị từ chối')),
      );
    }

    final isEdit = widget.initialReceipt != null;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          isEdit
              ? 'Chỉnh sửa phiếu nháp ${widget.initialReceipt!.id}'
              : 'Tạo phiếu nhập từ NCC',
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // CARD 1: Thông tin phiếu nhập
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.description_outlined,
                                color: AppColors.blue700,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '1. Thông tin phiếu nhập',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Mã phiếu: ${isEdit ? widget.initialReceipt!.id : 'Tự động tạo khi lưu'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.blue800,
                                ),
                              ),
                              Text(
                                'Ngày: ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          // Kho nhập hàng
                          if (_isLoadingWarehouses)
                            const Center(child: CircularProgressIndicator())
                          else if (!_isAdmin)
                            // Kho được cố định cho nhân viên kho
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.warehouse_rounded,
                                    color: AppColors.blue700,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Kho nhận hàng (Cố định theo phân công)',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.muted,
                                          ),
                                        ),
                                        Text(
                                          _selectedWarehouseName ??
                                              _selectedWarehouseId ??
                                              'Kho làm việc',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 18,
                                    color: AppColors.muted,
                                  ),
                                ],
                              ),
                            )
                          else
                            DropdownButtonFormField<String>(
                              initialValue: _selectedWarehouseId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Kho nhận hàng (*)',
                                prefixIcon: Icon(Icons.warehouse_outlined),
                              ),
                              items: _warehouses.map((w) {
                                return DropdownMenuItem<String>(
                                  value: w.id,
                                  child: Text(w.name),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedWarehouseId = val;
                                  final matched = _warehouses.firstWhere(
                                    (w) => w.id == val,
                                    orElse: () => _warehouses.first,
                                  );
                                  _selectedWarehouseName = matched.name;
                                });
                              },
                            ),

                          const SizedBox(height: 12),

                          // Nhà cung cấp
                          if (_isLoadingSuppliers)
                            const Center(child: CircularProgressIndicator())
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Nhà cung cấp (*)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                    if (_isAdmin)
                                      TextButton.icon(
                                        style: TextButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                          foregroundColor: AppColors.blue700,
                                        ),
                                        onPressed: () async {
                                          final newSupp =
                                              await Navigator.of(
                                                context,
                                              ).push<Supplier>(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      SupplierFormScreen(
                                                        controller:
                                                            SupplierController(),
                                                      ),
                                                ),
                                              );
                                          if (newSupp != null) {
                                            setState(() {
                                              _suppliers.insert(0, newSupp);
                                              _selectedSupplierId = newSupp.id;
                                            });
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.add_rounded,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'Thêm NCC mới',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: _openSupplierPicker,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _selectedSupplierId == null
                                            ? Colors.red.shade300
                                            : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    child: _selectedSupplier == null
                                        ? const Row(
                                            children: [
                                              Icon(
                                                Icons.business_outlined,
                                                color: AppColors.muted,
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Bấm để chọn Nhà cung cấp (*)',
                                                  style: TextStyle(
                                                    color: AppColors.muted,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              Icon(
                                                Icons
                                                    .keyboard_arrow_down_rounded,
                                                color: AppColors.muted,
                                              ),
                                            ],
                                          )
                                        : Row(
                                            children: [
                                              const CircleAvatar(
                                                radius: 18,
                                                backgroundColor:
                                                    AppColors.blue50,
                                                child: Icon(
                                                  Icons.business_rounded,
                                                  color: AppColors.blue700,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      _selectedSupplier!.name,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'SĐT: ${_selectedSupplier!.phone ?? 'Chưa có'} · ${_selectedSupplier!.address ?? 'Chưa có địa chỉ'}',
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        color: AppColors.muted,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    if (_selectedSupplier!
                                                                .email !=
                                                            null &&
                                                        _selectedSupplier!
                                                            .email!
                                                            .isNotEmpty)
                                                      Text(
                                                        'Email: ${_selectedSupplier!.email}',
                                                        style: const TextStyle(
                                                          fontSize: 9,
                                                          color:
                                                              AppColors.muted,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(
                                                Icons.swap_horiz_rounded,
                                                color: AppColors.blue700,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),

                          const SizedBox(height: 12),
                          if (_creatorName != null && _creatorName!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.person_outline_rounded,
                                    size: 16,
                                    color: AppColors.muted,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Người lập phiếu: $_creatorName',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.muted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          TextField(
                            controller: _noteController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Ghi chú (tùy chọn)',
                              hintText:
                                  'VD: Nhập theo hợp đồng số HD-2026/SSM...',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // CARD 2: Danh sách sản phẩm nhập
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.shopping_bag_outlined,
                                    color: AppColors.blue700,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '2. Sản phẩm nhập (*)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.blue50,
                                  foregroundColor: AppColors.blue800,
                                  elevation: 0,
                                ),
                                onPressed: () async {
                                  final selectedProd =
                                      await showModalBottomSheet<Product>(
                                        context: context,
                                        isScrollControlled: true,
                                        showDragHandle: true,
                                        builder: (_) => _ProductPickerSheet(
                                          products: _allProducts,
                                          selectedSupplierId:
                                              _selectedSupplierId,
                                        ),
                                      );
                                  if (selectedProd != null) {
                                    _onAddProductSelected(selectedProd);
                                  }
                                },
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Thêm sản phẩm'),
                              ),
                            ],
                          ),
                          const Divider(height: 16),

                          if (_selectedItems.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  'Chưa chọn sản phẩm nào. Bấm "Thêm sản phẩm" ở trên.',
                                  style: TextStyle(color: AppColors.muted),
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _selectedItems.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 16),
                              itemBuilder: (context, idx) {
                                final item = _selectedItems[idx];
                                return _GoodsReceiptItemRow(
                                  item: item,
                                  onChanged: () => setState(() {}),
                                  onDelete: () {
                                    setState(() {
                                      _selectedItems.removeAt(idx);
                                    });
                                  },
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Thanh xác nhận & tổng tiền phía dưới
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tổng tiền phiếu (${_selectedItems.length} SP):',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        formatReceiptVnd(_totalAmountCalculated),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.blue800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _isSubmitting ? null : _saveDraft,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text(
                            'LƯU NHÁP',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blue700,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _isSubmitting
                              ? null
                              : _submitConfirmReceipt,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                ),
                          label: Text(
                            _isSubmitting
                                ? 'ĐANG XỬ LÝ...'
                                : 'XÁC NHẬN NHẬP KHO',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dòng chỉnh sửa sản phẩm trong phiếu nhập
class _GoodsReceiptItemEditModel {
  _GoodsReceiptItemEditModel({
    required this.productId,
    required this.name,
    this.barcode,
    required this.unit,
    required this.currentStock,
    required this.quantity,
    required this.importPrice,
    required this.lotNo,
    this.expiryDate,
  });

  final String productId;
  final String name;
  final String? barcode;
  final String unit;
  final int currentStock;
  int quantity;
  int importPrice;
  String lotNo;
  DateTime? expiryDate;

  int get subtotal => quantity * importPrice;
}

class _GoodsReceiptItemRow extends StatelessWidget {
  const _GoodsReceiptItemRow({
    required this.item,
    required this.onChanged,
    required this.onDelete,
  });

  final _GoodsReceiptItemEditModel item;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final expiryText = item.expiryDate == null
        ? 'Chọn HSD'
        : '${item.expiryDate!.day}/${item.expiryDate!.month}/${item.expiryDate!.year}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'ĐVT: ${item.unit} · Mã: ${item.barcode ?? item.productId} · Tồn kho: ${item.currentStock}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Số lượng nhập
              Expanded(
                child: TextFormField(
                  initialValue: '${item.quantity}',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'SL nhập (*)',
                    isDense: true,
                  ),
                  onChanged: (val) {
                    item.quantity = int.tryParse(val) ?? 0;
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Đơn giá nhập
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: '${item.importPrice}',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Giá nhập (đ) (*)',
                    isDense: true,
                  ),
                  onChanged: (val) {
                    item.importPrice = int.tryParse(val) ?? 0;
                    onChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Số lô
              Expanded(
                child: TextFormField(
                  initialValue: item.lotNo,
                  decoration: const InputDecoration(
                    labelText: 'Số lô (tùy chọn)',
                    hintText: 'VD: L2026-A',
                    isDense: true,
                  ),
                  onChanged: (val) {
                    item.lotNo = val;
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Hạn sử dụng
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate:
                          item.expiryDate ??
                          DateTime.now().add(const Duration(days: 180)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      item.expiryDate = picked;
                      onChanged();
                    }
                  },
                  icon: const Icon(Icons.calendar_today_rounded, size: 14),
                  label: Text(expiryText, style: const TextStyle(fontSize: 10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Thành tiền: ${formatReceiptVnd(item.subtotal)}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.blue800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal chọn Nhà cung cấp
class _SupplierPickerSheet extends StatefulWidget {
  const _SupplierPickerSheet({
    required this.suppliers,
    this.selectedSupplierId,
    required this.userRole,
    this.onSupplierAdded,
  });

  final List<Supplier> suppliers;
  final String? selectedSupplierId;
  final String userRole;
  final ValueChanged<Supplier>? onSupplierAdded;

  @override
  State<_SupplierPickerSheet> createState() => _SupplierPickerSheetState();
}

class _SupplierPickerSheetState extends State<_SupplierPickerSheet> {
  String _query = '';
  late List<Supplier> _list;

  @override
  void initState() {
    super.initState();
    _list = List.from(widget.suppliers);
  }

  bool get _isAdmin => isAdminRole(widget.userRole);

  @override
  Widget build(BuildContext context) {
    final filtered = _list.where((s) {
      if (!s.isActive) return false;
      final q = _query.trim().toLowerCase();
      if (q.isEmpty) return true;
      return s.name.toLowerCase().contains(q) ||
          (s.phone != null && s.phone!.contains(q)) ||
          (s.address != null && s.address!.toLowerCase().contains(q)) ||
          (s.email != null && s.email!.toLowerCase().contains(q));
    }).toList();

    return SafeArea(
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.75,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chọn Nhà cung cấp',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (_isAdmin)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.blue700,
                    ),
                    onPressed: () async {
                      final newSupp = await Navigator.of(context)
                          .push<Supplier>(
                            MaterialPageRoute(
                              builder: (_) => SupplierFormScreen(
                                controller: SupplierController(),
                              ),
                            ),
                          );
                      if (newSupp != null && mounted && context.mounted) {
                        setState(() {
                          _list.insert(0, newSupp);
                        });
                        widget.onSupplierAdded?.call(newSupp);
                        Navigator.pop(context, newSupp);
                      }
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(
                      'Thêm NCC mới',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              onChanged: (val) => setState(() => _query = val),
              decoration: const InputDecoration(
                hintText: 'Tìm theo tên, SĐT hoặc địa chỉ NCC',
                prefixIcon: Icon(Icons.search_rounded),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'Không tìm thấy nhà cung cấp đang hoạt động.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final s = filtered[idx];
                        final isSelected = s.id == widget.selectedSupplierId;
                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: AppColors.blue50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? AppColors.blue700
                                : AppColors.blue50,
                            child: Icon(
                              Icons.business_rounded,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.blue700,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            s.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.bold,
                              color: isSelected
                                  ? AppColors.blue900
                                  : AppColors.ink,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              if (s.phone != null && s.phone!.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone_outlined,
                                      size: 13,
                                      color: AppColors.muted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      s.phone!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              if (s.address != null && s.address!.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 13,
                                      color: AppColors.muted,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        s.address!,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.muted,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              if (s.email != null && s.email!.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.email_outlined,
                                      size: 13,
                                      color: AppColors.muted,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        s.email!,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.muted,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.blue700,
                                )
                              : null,
                          onTap: () => Navigator.pop(context, s),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal chọn sản phẩm để thêm vào phiếu nhập
class _ProductPickerSheet extends StatefulWidget {
  const _ProductPickerSheet({required this.products, this.selectedSupplierId});

  final List<Product> products;
  final String? selectedSupplierId;

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.products.where((p) {
      if (!p.isActive) return false;
      if (widget.selectedSupplierId != null &&
          p.supplierId != null &&
          p.supplierId!.isNotEmpty &&
          p.supplierId != widget.selectedSupplierId) {
        return false;
      }
      final q = _query.trim().toLowerCase();
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          (p.barcode != null && p.barcode!.contains(q));
    }).toList();

    return SafeArea(
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.75,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            const Text(
              'Chọn sản phẩm nhập kho',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              onChanged: (val) => setState(() => _query = val),
              decoration: const InputDecoration(
                hintText: 'Tìm theo tên hoặc mã vạch sản phẩm',
                prefixIcon: Icon(Icons.search_rounded),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'Không tìm thấy sản phẩm phù hợp.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final p = filtered[idx];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          leading: p.imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: Image.network(
                                      p.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const Icon(
                                        Icons.inventory_2_outlined,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ),
                                )
                              : const CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.blue50,
                                  child: Icon(
                                    Icons.inventory_2_outlined,
                                    color: AppColors.blue700,
                                    size: 20,
                                  ),
                                ),
                          title: Text(
                            p.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Barcode: ${p.barcode ?? 'Chưa có'} · ĐVT: ${p.packageSize ?? 'SP'} · Tồn: ${p.stock}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.add_circle_outline_rounded,
                            color: AppColors.blue700,
                          ),
                          onTap: () => Navigator.pop(context, p),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Màn hình Chi tiết Phiếu nhập kho từ Nhà cung cấp
class GoodsReceiptDetailScreen extends StatefulWidget {
  const GoodsReceiptDetailScreen({
    required this.receiptId,
    required this.userRole,
    this.initialReceipt,
    super.key,
  });

  final String receiptId;
  final String userRole;
  final GoodsReceipt? initialReceipt;

  @override
  State<GoodsReceiptDetailScreen> createState() =>
      _GoodsReceiptDetailScreenState();
}

class _GoodsReceiptDetailScreenState extends State<GoodsReceiptDetailScreen> {
  final _goodsReceiptService = GoodsReceiptService();
  GoodsReceipt? _receipt;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _receipt = widget.initialReceipt;
    _isLoading = widget.initialReceipt == null;
    _loadDetail();
  }

  @override
  void dispose() {
    _goodsReceiptService.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    try {
      final item = await _goodsReceiptService.getGoodsReceiptById(
        widget.receiptId,
      );
      if (!mounted) return;
      setState(() {
        _receipt = item;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = formatGoodsReceiptApiError(e);
      });
    }
  }

  Future<void> _handleConfirmReceipt() async {
    final receipt = _receipt;
    if (receipt == null || !receipt.isDraft || _isSubmitting) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận hoàn tất nhập kho'),
        content: Text(
          'Phiếu nhập ${receipt.id} sẽ chuyển sang Hoàn tất. Tồn kho và giá nhập sẽ được cập nhật ngay vào hệ thống.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Quay lại'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Xác nhận',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    try {
      final updated = await _goodsReceiptService.completeGoodsReceipt(
        receipt.id,
      );
      if (!mounted) return;
      setState(() {
        _receipt = updated;
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã hoàn tất nhập kho thành công!'),
          backgroundColor: Colors.green[700],
        ),
      );
      _loadDetail();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thao tác thất bại: ${formatGoodsReceiptApiError(e)}'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  Future<void> _handleCancelReceipt() async {
    final receipt = _receipt;
    if (receipt == null || !receipt.isDraft || _isSubmitting) return;

    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hủy phiếu nhập nháp'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bạn có chắc chắn muốn hủy phiếu nhập nháp này không? '
              'Phiếu sau khi hủy sẽ không thể chỉnh sửa hoặc hoàn tất lại.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do hủy (tùy chọn)',
                hintText: 'VD: Thay đổi kế hoạch nhập, sai nhà cung cấp...',
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Quay lại'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Xác nhận hủy',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    try {
      final updated = await _goodsReceiptService.cancelGoodsReceipt(
        receipt.id,
        reason: reasonController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _receipt = updated;
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã hủy phiếu nhập thành công.'),
          backgroundColor: Colors.orange[800],
        ),
      );
      _loadDetail();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không thể hủy phiếu: ${formatGoodsReceiptApiError(e)}',
          ),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text('Chi tiết phiếu ${_receipt?.id ?? widget.receiptId}'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _loadDetail,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _receipt == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadDetail,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final req = _receipt!;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Thông tin chung
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Trạng thái phiếu',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: req.isCompleted
                                  ? Colors.green.shade50
                                  : req.isCancelled
                                  ? Colors.red.shade50
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              req.statusDisplay,
                              style: TextStyle(
                                color: req.isCompleted
                                    ? Colors.green.shade800
                                    : req.isCancelled
                                    ? Colors.red.shade800
                                    : Colors.orange.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      _buildInfoRow('Mã phiếu', req.id),
                      _buildInfoRow(
                        'Nhà cung cấp',
                        req.supplierName ?? req.supplierId ?? 'Chưa rõ',
                      ),
                      if (req.supplierPhone != null)
                        _buildInfoRow('SĐT nhà cung cấp', req.supplierPhone!),
                      if (req.supplierAddress != null)
                        _buildInfoRow('Địa chỉ NCC', req.supplierAddress!),
                      _buildInfoRow(
                        'Kho nhập hàng',
                        req.warehouseName ?? req.warehouseId,
                      ),
                      _buildInfoRow('Người lập phiếu', req.creatorDisplay),
                      _buildInfoRow(
                        'Thời gian tạo',
                        _formatDate(req.createdAt),
                      ),
                      if (req.completedAt != null)
                        _buildInfoRow(
                          'Thời gian hoàn tất',
                          _formatDate(req.completedAt!),
                        ),
                      if (req.note != null && req.note!.isNotEmpty)
                        _buildInfoRow('Ghi chú', req.note!),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Danh sách sản phẩm
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Danh sách sản phẩm nhập',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${req.items.length} mặt hàng',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              color: const Color(0xFFF1F5F9),
                              child: const Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      'Tên sản phẩm',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'ĐVT',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'SL',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'Giá nhập',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: req.items.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final item = req.items[idx];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 4,
                                            child: Text(
                                              item.productName ??
                                                  'Sản phẩm ${item.productId}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              item.displayUnit,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              '${item.quantity}',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              formatReceiptVnd(
                                                item.importPrice,
                                              ),
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (item.lotNo != null ||
                                          item.expiryDate != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          '${item.lotNo != null ? 'Lô: ${item.lotNo} ' : ''}${item.expiryDate != null ? '· HSD: ${item.expiryDate!.day}/${item.expiryDate!.month}/${item.expiryDate!.year}' : ''}',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            color: AppColors.muted,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tổng tiền chính thức:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            formatReceiptVnd(req.calculatedTotal),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.blue800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Thao tác cho phiếu Nháp
        if (req.isDraft)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isSubmitting ? null : _handleCancelReceipt,
                    child: const Text('HỦY PHIẾU'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            final res = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => CreateGoodsReceiptScreen(
                                  userRole: widget.userRole,
                                  initialReceipt: req,
                                ),
                              ),
                            );
                            if (res == true) _loadDetail();
                          },
                    child: const Text('SỬA PHIẾU'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isSubmitting ? null : _handleConfirmReceipt,
                    child: Text(
                      _isSubmitting ? 'ĐANG XỬ LÝ...' : 'XÁC NHẬN NHẬP KHO',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/${dt.year} $h:$min';
  }
}

/// Định danh màn hình Quản lý Nhà cung cấp theo Feature-based Architecture
typedef SupplierManagementScreen = SupplierListScreen;
