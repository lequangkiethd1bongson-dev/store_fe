import 'package:flutter/material.dart';

import '../core/network/api_client.dart';
import '../models/product.dart';
import '../models/restock_models.dart';
import '../services/product_service.dart';
import '../services/restock_service.dart';
import '../theme/app_theme.dart';

/// Màn hình Tạo phiếu yêu cầu xuất hàng từ kho (chỉ dành cho Quản lý cửa hàng - store_manager)
class CreateRestockRequestScreen extends StatefulWidget {
  const CreateRestockRequestScreen({
    required this.userRole,
    this.onCreated,
    super.key,
  });

  final String userRole;
  final VoidCallback? onCreated;

  @override
  State<CreateRestockRequestScreen> createState() =>
      _CreateRestockRequestScreenState();
}

class _CreateRestockRequestScreenState
    extends State<CreateRestockRequestScreen> {
  final _productService = ProductService();
  final _restockService = RestockService();
  final _noteController = TextEditingController();

  List<WarehouseOption> _warehouses = [];
  String? _selectedWarehouseId;
  bool _isLoadingWarehouses = true;
  String? _warehouseError;

  List<Product> _allProducts = [];
  bool _isLoadingProducts = true;
  String? _productError;
  String _productSearchQuery = '';

  // Danh sách các sản phẩm được chọn: productId -> quantity
  final Map<String, int> _selectedItems = {};
  bool _isSubmitting = false;

  bool get _isStoreManager => widget.userRole == 'STORE_MANAGER';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _productService.dispose();
    _restockService.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    _loadWarehouses();
    _loadProducts();
  }

  Future<void> _loadWarehouses() async {
    try {
      final warehouses = await _productService.getWarehouses();
      if (!mounted) return;
      setState(() {
        _warehouses = warehouses;
        _selectedWarehouseId = warehouses.isNotEmpty
            ? warehouses.first.id
            : null;
        _isLoadingWarehouses = false;
        _warehouseError = warehouses.isEmpty
            ? 'Chưa có kho nào trong hệ thống.'
            : null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingWarehouses = false;
        _warehouseError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingWarehouses = false;
        _warehouseError = 'Không thể tải danh sách kho: $e';
      });
    }
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _productService.getStoreProducts();
      if (!mounted) return;
      setState(() {
        _allProducts = products;
        _isLoadingProducts = false;
        _productError = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingProducts = false;
        _productError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingProducts = false;
        _productError = 'Không thể tải danh sách sản phẩm: $e';
      });
    }
  }

  void _setItemQuantity(String productId, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _selectedItems.remove(productId);
      } else {
        _selectedItems[productId] = quantity;
      }
    });
  }

  Future<void> _submitRequest() async {
    if (!_isStoreManager) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chỉ Quản lý cửa hàng (store_manager) mới có quyền tạo phiếu yêu cầu.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedWarehouseId == null || _selectedWarehouseId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn kho xuất hàng.')),
      );
      return;
    }

    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất 1 sản phẩm và số lượng > 0.'),
        ),
      );
      return;
    }

    final itemsPayload = _selectedItems.entries.map((entry) {
      return {
        'productId': entry.key,
        'quantity': entry.value,
        'requestedQuantity': entry.value,
      };
    }).toList();

    setState(() => _isSubmitting = true);

    try {
      final request = await _restockService.createRequest(
        warehouseId: _selectedWarehouseId!,
        items: itemsPayload,
        note: _noteController.text,
      );

      if (!mounted) return;
      widget.onCreated?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã tạo phiếu yêu cầu xuất hàng thành công (Mã: ${request.id.isNotEmpty ? request.id : 'Mới'})!',
          ),
          backgroundColor: Colors.green[700],
        ),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tạo phiếu yêu cầu: ${e.message}'),
          backgroundColor: Colors.red[700],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi khi tạo phiếu yêu cầu: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isStoreManager) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tạo phiếu yêu cầu')),
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
                  'Role sales không được thấy hoặc sử dụng chức năng tạo phiếu yêu cầu nhập hàng từ kho.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filteredProducts = _allProducts.where((p) {
      final q = _productSearchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          (p.barcode != null && p.barcode!.contains(q));
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yêu cầu xuất hàng từ kho'),
            Text(
              'Chức năng dành cho Quản lý cửa hàng',
              style: TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Chọn kho xuất hàng
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
                                Icons.warehouse_outlined,
                                color: AppColors.blue700,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '1. Chọn kho nhận yêu cầu (*)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          if (_isLoadingWarehouses)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (_warehouseError != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                _warehouseError!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            )
                          else
                            DropdownButtonFormField<String>(
                              initialValue: _selectedWarehouseId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Kho cấp hàng',
                                prefixIcon: Icon(Icons.location_city_rounded),
                              ),
                              items: _warehouses.map((w) {
                                return DropdownMenuItem<String>(
                                  value: w.id,
                                  child: Text(w.name),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() => _selectedWarehouseId = val);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Chọn danh sách sản phẩm & nhập số lượng
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
                                    Icons.shopping_basket_outlined,
                                    color: AppColors.blue700,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '2. Chọn sản phẩm & số lượng (*)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.blue50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Đã chọn: ${_selectedItems.length} SP',
                                  style: const TextStyle(
                                    color: AppColors.blue800,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          TextField(
                            onChanged: (val) =>
                                setState(() => _productSearchQuery = val),
                            decoration: const InputDecoration(
                              hintText: 'Tìm theo tên hoặc mã vạch',
                              prefixIcon: Icon(Icons.search_rounded),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_isLoadingProducts)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (_productError != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Column(
                                children: [
                                  Text(
                                    _productError!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton(
                                    onPressed: _loadProducts,
                                    child: const Text('Tải lại sản phẩm'),
                                  ),
                                ],
                              ),
                            )
                          else if (filteredProducts.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Text(
                                  'Không tìm thấy sản phẩm nào.',
                                  style: TextStyle(color: AppColors.muted),
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredProducts.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final product = filteredProducts[index];
                                final currentQty =
                                    _selectedItems[product.id] ?? 0;

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Mã: ${product.barcode ?? 'Chưa có'} · Giá: ${product.price}đ',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                  trailing: SizedBox(
                                    width: 130,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                          ),
                                          onPressed: currentQty > 0
                                              ? () => _setItemQuantity(
                                                  product.id,
                                                  currentQty - 1,
                                                )
                                              : null,
                                        ),
                                        Text(
                                          '$currentQty',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                            color: currentQty > 0
                                                ? AppColors.blue800
                                                : Colors.black54,
                                          ),
                                        ),
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                            color: AppColors.blue700,
                                          ),
                                          onPressed: () => _setItemQuantity(
                                            product.id,
                                            currentQty + 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Ghi chú tùy chọn
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
                                Icons.notes_rounded,
                                color: AppColors.blue700,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '3. Ghi chú (tùy chọn)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _noteController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              hintText: 'VD: Ưu tiên giao sớm ca sáng để kịp trưng bày lên kệ...',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Thanh xác nhận gửi yêu cầu ở dưới cùng
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _submitRequest,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white),
                  label: Text(
                    _isSubmitting
                        ? 'ĐANG GỬI YÊU CẦU...'
                        : 'XÁC NHẬN GỬI YÊU CẦU CẤP HÀNG',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Màn hình Danh sách Phiếu yêu cầu hàng của Cửa hàng (chỉ dành cho Quản lý cửa hàng - store_manager)
class RestockRequestsScreen extends StatefulWidget {
  const RestockRequestsScreen({required this.userRole, super.key});

  final String userRole;

  @override
  State<RestockRequestsScreen> createState() => _RestockRequestsScreenState();
}

class _RestockRequestsScreenState extends State<RestockRequestsScreen> {
  final _restockService = RestockService();
  String _selectedStatus = 'ALL';
  List<RestockRequest> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;

  bool get _isStoreManager => widget.userRole == 'STORE_MANAGER';

  static const _statusOptions = [
    {'value': 'ALL', 'label': 'Tất cả'},
    {'value': 'pending', 'label': 'Chờ duyệt'},
    {'value': 'approved', 'label': 'Đã duyệt'},
    {'value': 'rejected', 'label': 'Từ chối'},
    {'value': 'exported', 'label': 'Đang xuất hàng'},
    {'value': 'received', 'label': 'Đã nhận hàng'},
  ];

  @override
  void initState() {
    super.initState();
    if (_isStoreManager) {
      _loadRequests();
    }
  }

  @override
  void dispose() {
    _restockService.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final statusParam = _selectedStatus == 'ALL' ? null : _selectedStatus;
      final list = await _restockService.getRequests(status: statusParam);
      if (!mounted) return;
      setState(() {
        _requests = list;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể nạp danh sách phiếu: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isStoreManager) {
      return Scaffold(
        appBar: AppBar(title: const Text('Phiếu yêu cầu hàng')),
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
                  'Role sales không được thấy hoặc sử dụng danh sách phiếu yêu cầu hàng.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Phiếu yêu cầu xuất hàng'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _loadRequests,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.blue700,
        onPressed: () async {
          final res = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) =>
                  CreateRestockRequestScreen(userRole: widget.userRole),
            ),
          );
          if (res == true) _loadRequests();
        },
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'TẠO YÊU CẦU MỚI',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Thanh lọc trạng thái
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                          _loadRequests();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadRequests,
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
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
              onPressed: _loadRequests,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ),
        ],
      );
    }

    if (_requests.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: const [
          Icon(Icons.assignment_outlined, size: 64, color: AppColors.muted),
          SizedBox(height: 16),
          Text(
            'Chưa có phiếu yêu cầu nào.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            'Bấm "Tạo yêu cầu mới" bên dưới để gửi yêu cầu hàng đến kho.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final req = _requests[index];
        return _RestockRequestCard(
          request: req,
          onTap: () async {
            final res = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => RestockRequestDetailScreen(
                  requestId: req.id,
                  userRole: widget.userRole,
                  initialRequest: req,
                ),
              ),
            );
            if (res == true) _loadRequests();
          },
        );
      },
    );
  }
}

class _RestockRequestCard extends StatelessWidget {
  const _RestockRequestCard({required this.request, required this.onTap});

  final RestockRequest request;
  final VoidCallback onTap;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange[800]!;
      case 'approved':
        return AppColors.blue700;
      case 'rejected':
        return Colors.red[700]!;
      case 'exported':
      case 'shipping':
        return Colors.purple[700]!;
      case 'received':
      case 'delivered':
        return Colors.green[700]!;
      default:
        return AppColors.ink;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(request.status);

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
                    'Mã phiếu: ${request.id.length > 8 ? request.id.substring(0, 8) : request.id}',
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
                      request.statusDisplay,
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
                    Icons.warehouse_outlined,
                    size: 16,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Kho: ${request.warehouseName ?? request.warehouseId}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    size: 16,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Sản phẩm: ${request.itemCount ?? request.items.length} mặt hàng',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              if (request.canConfirmReceipt) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        color: Colors.purple,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Hàng đang được kho vận chuyển tới cửa hàng. Bấm để xem và xác nhận đã nhận hàng.',
                          style: TextStyle(
                            color: Colors.purple,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Màn hình Chi tiết Phiếu yêu cầu & Xác nhận nhận hàng (chỉ dành cho Quản lý cửa hàng - store_manager)
class RestockRequestDetailScreen extends StatefulWidget {
  const RestockRequestDetailScreen({
    required this.requestId,
    required this.userRole,
    this.initialRequest,
    super.key,
  });

  final String requestId;
  final String userRole;
  final RestockRequest? initialRequest;

  @override
  State<RestockRequestDetailScreen> createState() =>
      _RestockRequestDetailScreenState();
}

class _RestockRequestDetailScreenState
    extends State<RestockRequestDetailScreen> {
  final _restockService = RestockService();
  RestockRequest? _request;
  bool _isLoading = true;
  bool _isConfirming = false;
  String? _error;

  bool get _isStoreManager => widget.userRole == 'STORE_MANAGER';

  @override
  void initState() {
    super.initState();
    _request = widget.initialRequest;
    _isLoading = widget.initialRequest == null;
    if (_isStoreManager) {
      _loadDetail();
    }
  }

  @override
  void dispose() {
    _restockService.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    try {
      final req = await _restockService.getRequestById(widget.requestId);
      if (!mounted) return;
      setState(() {
        _request = req;
        _isLoading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Không thể nạp chi tiết phiếu: $e';
      });
    }
  }

  Future<void> _handleConfirmReceipt() async {
    if (!_isStoreManager) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ Quản lý cửa hàng mới được xác nhận đã nhận hàng.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final req = _request;
    if (req == null || !req.canConfirmReceipt || _isConfirming) return;

    setState(() => _isConfirming = true);

    try {
      final updatedReq = await _restockService.confirmReceipt(
        exportId: req.exportId!,
        requestId: req.id,
      );
      if (!mounted) return;

      setState(() {
        _request = updatedReq;
        _isConfirming = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Xác nhận đã nhận hàng thành công! Tồn kệ cửa hàng đã được cập nhật.',
          ),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 4),
        ),
      );

      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isConfirming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xác nhận thất bại: ${e.message}'),
          backgroundColor: Colors.red[700],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isConfirming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi khi xác nhận nhận hàng: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isStoreManager) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết phiếu yêu cầu')),
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
                  'Role sales không được thấy hoặc xác nhận nhận hàng.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text('Chi tiết phiếu ${_request?.id ?? widget.requestId}'),
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

    if (_error != null && _request == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadDetail,
                child: const Text('Tải lại'),
              ),
            ],
          ),
        ),
      );
    }

    final req = _request!;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Card Tổng quan thông tin phiếu
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
                              color: AppColors.blue50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              req.statusDisplay,
                              style: const TextStyle(
                                color: AppColors.blue800,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Text('Mã phiếu: ${req.id}'),
                      const SizedBox(height: 4),
                      Text('Kho nhận: ${req.warehouseName ?? req.warehouseId}'),
                      const SizedBox(height: 4),
                      Text('Thời gian tạo: ${_formatDate(req.createdAt)}'),
                      if (req.createdBy != null) ...[
                        const SizedBox(height: 4),
                        Text('Người tạo: ${req.createdBy}'),
                      ],
                      if (req.approvedBy != null) ...[
                        const SizedBox(height: 4),
                        Text('Người xử lý: ${req.approvedBy}'),
                      ],
                      if (req.note != null && req.note!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Ghi chú: ${req.note}',
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Nếu bị từ chối -> hiển thị lý do từ chối
              if (req.status == 'rejected' &&
                  req.rejectReason != null &&
                  req.rejectReason!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Card(
                  color: Colors.red.shade50,
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
                            Icon(Icons.cancel_outlined, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Lý do từ chối từ Kho:',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          req.rejectReason!,
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Danh sách sản phẩm trong phiếu
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Danh sách sản phẩm yêu cầu',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Divider(height: 16),
                      if (req.items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Không có chi tiết sản phẩm nào.'),
                        )
                      else
                        ...req.items.map((item) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              item.productName ?? 'Sản phẩm ${item.productId}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text('Mã SP: ${item.productId}'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Yêu cầu: ${item.requestedQuantity}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (item.approvedQuantity != null)
                                  Text(
                                    'Kho duyệt: ${item.approvedQuantity}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Nút Xác nhận đã nhận hàng (chỉ hiển thị khi phiếu đang vận chuyển shipping)
        if (req.canConfirmReceipt)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isConfirming ? null : _handleConfirmReceipt,
                icon: _isConfirming
                    ? const SizedBox(
                        width: 20,
                        height: 20,
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
                  _isConfirming ? 'ĐANG XÁC NHẬN...' : 'XÁC NHẬN ĐÃ NHẬN HÀNG',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
      ],
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

/// Kiểm tra role có phải Quản lý kho (kho_manager / WAREHOUSE_MANAGER)
bool isWarehouseManagerRole(String? role) {
  final clean = (role ?? '').trim().toUpperCase();
  return clean == 'WAREHOUSE_MANAGER' ||
      clean == 'KHO_MANAGER' ||
      clean == 'KHO_QUAN_LY' ||
      clean == 'QUAN_LY_KHO';
}

/// Định dạng lỗi API theo chuẩn HTTP Status Code cho màn hình phiếu kho
String formatRestockApiError(Object e) {
  if (e is ApiException) {
    switch (e.statusCode) {
      case 401:
        return 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại (401).';
      case 403:
        return 'Tài khoản không có quyền thực hiện thao tác này hoặc chưa được kích hoạt (403).';
      case 404:
        return 'Không tìm thấy phiếu yêu cầu trên hệ thống (404).';
      case 409:
        return e.message.isNotEmpty
            ? e.message
            : 'Trạng thái phiếu không hợp lệ hoặc số lượng tồn kho không đủ (409).';
      case 500:
        return 'Lỗi máy chủ (500). Vui lòng thử lại sau.';
      default:
        return e.message;
    }
  }
  return e.toString().replaceFirst('ApiException: ', '');
}

/// Màn hình Danh sách Phiếu yêu cầu dành cho Quản lý Kho (kho_manager / WAREHOUSE_MANAGER)
class WarehouseRestockRequestsScreen extends StatefulWidget {
  const WarehouseRestockRequestsScreen({required this.userRole, super.key});

  final String userRole;

  @override
  State<WarehouseRestockRequestsScreen> createState() =>
      _WarehouseRestockRequestsScreenState();
}

class _WarehouseRestockRequestsScreenState
    extends State<WarehouseRestockRequestsScreen> {
  final _restockService = RestockService();
  String _selectedStatus = 'ALL';
  List<RestockRequest> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;

  bool get _isWarehouseManager => isWarehouseManagerRole(widget.userRole);

  static const _statusOptions = [
    {'value': 'ALL', 'label': 'Tất cả'},
    {'value': 'pending', 'label': 'Chờ xử lý'},
    {'value': 'approved', 'label': 'Đã duyệt'},
    {'value': 'rejected', 'label': 'Đã từ chối'},
    {'value': 'exported', 'label': 'Đã xuất kho'},
    {'value': 'received', 'label': 'Đã nhận'},
  ];

  @override
  void initState() {
    super.initState();
    if (_isWarehouseManager) {
      _loadRequests();
    }
  }

  @override
  void dispose() {
    _restockService.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final statusParam = _selectedStatus == 'ALL' ? null : _selectedStatus;
      final list = await _restockService.getWarehouseRequests(
        status: statusParam,
      );
      if (!mounted) return;
      setState(() {
        _requests = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = formatRestockApiError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isWarehouseManager) {
      return Scaffold(
        appBar: AppBar(title: const Text('Phiếu yêu cầu từ cửa hàng')),
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
                  'Role nhân viên kho (kho) không được truy cập chức năng này. Chỉ Quản lý kho mới được xem và xử lý phiếu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Phiếu yêu cầu từ cửa hàng'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _loadRequests,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                          _loadRequests();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadRequests,
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
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
              onPressed: _loadRequests,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ),
        ],
      );
    }

    if (_requests.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: const [
          Icon(Icons.assignment_outlined, size: 64, color: AppColors.muted),
          SizedBox(height: 16),
          Text(
            'Không có phiếu yêu cầu nào.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            'Chưa có yêu cầu xuất hàng nào từ các cửa hàng gửi tới kho này.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final req = _requests[index];
        return _WarehouseRestockRequestCard(
          request: req,
          onTap: () async {
            final res = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => WarehouseRestockRequestDetailScreen(
                  requestId: req.id,
                  userRole: widget.userRole,
                  initialRequest: req,
                ),
              ),
            );
            if (res == true) _loadRequests();
          },
        );
      },
    );
  }
}

class _WarehouseRestockRequestCard extends StatelessWidget {
  const _WarehouseRestockRequestCard({
    required this.request,
    required this.onTap,
  });

  final RestockRequest request;
  final VoidCallback onTap;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange[800]!;
      case 'approved':
        return AppColors.blue700;
      case 'rejected':
        return Colors.red[700]!;
      case 'exported':
      case 'shipping':
        return Colors.purple[700]!;
      case 'received':
      case 'delivered':
        return Colors.green[700]!;
      default:
        return AppColors.ink;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(request.status);
    final formattedDate =
        '${request.createdAt.day.toString().padLeft(2, '0')}/${request.createdAt.month.toString().padLeft(2, '0')}/${request.createdAt.year} ${request.createdAt.hour.toString().padLeft(2, '0')}:${request.createdAt.minute.toString().padLeft(2, '0')}';

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
                    'Mã phiếu: ${request.id.length > 8 ? request.id.substring(0, 8) : request.id}',
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
                      request.statusDisplay,
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
                    Icons.storefront_outlined,
                    size: 16,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Cửa hàng: ${request.storeName ?? request.storeId}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Ngày tạo: $formattedDate',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.shopping_bag_outlined,
                    size: 16,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${request.itemCount ?? request.items.length} mặt hàng',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
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

/// Màn hình Chi tiết Phiếu yêu cầu & Duyệt / Từ chối / Xuất hàng (dành cho Quản lý Kho - kho_manager)
class WarehouseRestockRequestDetailScreen extends StatefulWidget {
  const WarehouseRestockRequestDetailScreen({
    required this.requestId,
    required this.userRole,
    this.initialRequest,
    super.key,
  });

  final String requestId;
  final String userRole;
  final RestockRequest? initialRequest;

  @override
  State<WarehouseRestockRequestDetailScreen> createState() =>
      _WarehouseRestockRequestDetailScreenState();
}

class _WarehouseRestockRequestDetailScreenState
    extends State<WarehouseRestockRequestDetailScreen> {
  final _restockService = RestockService();
  RestockRequest? _request;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  bool get _isWarehouseManager => isWarehouseManagerRole(widget.userRole);

  @override
  void initState() {
    super.initState();
    _request = widget.initialRequest;
    _isLoading = widget.initialRequest == null;
    if (_isWarehouseManager) {
      _loadDetail();
    }
  }

  @override
  void dispose() {
    _restockService.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    try {
      final req = await _restockService.getWarehouseRequestById(
        widget.requestId,
      );
      if (!mounted) return;
      setState(() {
        _request = req;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = formatRestockApiError(e);
      });
    }
  }

  /// Xử lý duyệt phiếu yêu cầu: cho phép sửa approvedQuantity từng món & xác nhận
  Future<void> _showApproveDialog() async {
    final req = _request;
    if (req == null) return;

    final approvedQtyMap = <String, int>{};
    for (final item in req.items) {
      approvedQtyMap[item.productId] =
          item.approvedQuantity ?? item.requestedQuantity;
    }

    final confirm = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 10,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Duyệt phiếu yêu cầu xuất hàng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Kiểm tra và điều chỉnh số lượng duyệt cho từng sản phẩm. Số lượng 0 dùng để không cấp sản phẩm đó.',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                    const Divider(height: 20),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: req.items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final item = req.items[idx];
                          final currentApproved =
                              approvedQtyMap[item.productId] ??
                              item.requestedQuantity;

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              item.productName ?? 'Sản phẩm ${item.productId}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Mã: ${item.productId}'),
                                Text(
                                  'Cửa hàng yêu cầu: ${item.requestedQuantity}'
                                  '${item.warehouseStock != null ? ' · Tồn kho: ${item.warehouseStock}' : ''}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                            trailing: SizedBox(
                              width: 120,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                    onPressed: currentApproved > 0
                                        ? () {
                                            setSheetState(() {
                                              approvedQtyMap[item.productId] =
                                                  currentApproved - 1;
                                            });
                                          }
                                        : null,
                                  ),
                                  Text(
                                    '$currentApproved',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: currentApproved > 0
                                          ? AppColors.blue800
                                          : Colors.red,
                                    ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      color: AppColors.blue700,
                                    ),
                                    onPressed: () {
                                      setSheetState(() {
                                        approvedQtyMap[item.productId] =
                                            currentApproved + 1;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(bottomSheetContext, true),
                      icon: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'XÁC NHẬN DUYỆT PHIẾU',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (confirm != true) return;

    final itemsPayload = approvedQtyMap.entries.map((e) {
      return {
        'productId': e.key,
        'approvedQuantity': e.value,
        'quantity': e.value,
      };
    }).toList();

    setState(() => _isSubmitting = true);

    try {
      final updatedReq = await _restockService.approveRequest(
        requestId: req.id,
        items: itemsPayload,
      );
      if (!mounted) return;
      setState(() {
        _request = updatedReq;
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã duyệt phiếu yêu cầu thành công!'),
          backgroundColor: Colors.green[700],
        ),
      );
      _loadDetail();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formatRestockApiError(e)),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  /// Xử lý từ chối / hủy phiếu yêu cầu
  Future<void> _showRejectDialog({String? defaultReason}) async {
    final req = _request;
    if (req == null || _isSubmitting) return;

    final initialReason =
        defaultReason ??
        (req.isApproved
            ? 'Kho không đủ số lượng hàng tồn thực tế để xuất'
            : '');
    final reasonController = TextEditingController(text: initialReason);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 40),
          title: Text(
            req.isApproved
                ? 'Hủy / Từ chối phiếu đã duyệt'
                : 'Từ chối phiếu yêu cầu',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                req.isApproved
                    ? 'Bạn muốn hủy phiếu đã duyệt này do không đủ hàng tồn kho?'
                    : 'Vui lòng nhập lý do từ chối yêu cầu từ cửa hàng:',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Lý do từ chối / hủy',
                  hintText: 'VD: Kho hiện tại đang hết sản phẩm này...',
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
              onPressed: () {
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập lý do từ chối.'),
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Xác nhận hủy phiếu',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final reason = reasonController.text.trim();
    setState(() => _isSubmitting = true);

    try {
      final updatedReq = await _restockService.rejectRequest(
        requestId: req.id,
        rejectReason: reason,
      );
      if (!mounted || !context.mounted) return;
      setState(() {
        _request = updatedReq;
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã hủy / từ chối phiếu yêu cầu.'),
          backgroundColor: Colors.orange[800],
        ),
      );
      _loadDetail();
    } catch (e) {
      if (!mounted || !context.mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formatRestockApiError(e)),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  /// Xử lý xuất kho gửi cửa hàng
  Future<void> _showExportDialog() async {
    final req = _request;
    if (req == null || _isSubmitting) return;

    bool isConfirmedPrepared = false;
    final shortageItems = <RestockRequestItem>[];

    for (final item in req.items) {
      final approved = item.approvedQuantity ?? item.requestedQuantity;
      if (item.warehouseStock != null && item.warehouseStock! < approved) {
        shortageItems.add(item);
      }
    }
    final hasLowStockWarning = shortageItems.isNotEmpty;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (bottomSheetContext) {
        bool isExportingInSheet = false;
        String? sheetErrorMessage;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 10,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          color: AppColors.blue700,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Xác nhận Xuất kho & Gửi cửa hàng',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    if (hasLowStockWarning)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'CẢNH BÁO THIẾU TỒN KHO THỰC TẾ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Các mặt hàng sau có tồn kho ít hơn số lượng cần xuất:\n'
                              '${shortageItems.map((i) {
                                final qty = i.approvedQuantity ?? i.requestedQuantity;
                                return '• ${i.productName ?? i.productId}: Cần xuất $qty SP | Tồn thực tế: ${i.warehouseStock} SP (Thiếu ${qty - i.warehouseStock!} SP)';
                              }).join('\n')}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.brown.shade900,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (sheetErrorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                sheetErrorMessage!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Text(
                      'Danh sách mặt hàng xuất kho:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.35,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: req.items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final item = req.items[idx];
                          final qty =
                              item.approvedQuantity ?? item.requestedQuantity;
                          final stock = item.warehouseStock;
                          final isShort = stock != null && stock < qty;

                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              item.productName ?? 'SP ${item.productId}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            subtitle: Text(
                              'Số lượng xuất: $qty SP'
                              '${stock != null ? ' · Tồn thực tế: $stock SP' : ''}'
                              '${isShort ? ' (Thiếu ${qty - stock} SP)' : ''}',
                              style: TextStyle(
                                fontSize: 10,
                                color: isShort ? Colors.red : AppColors.muted,
                                fontWeight: isShort
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isShort
                                    ? Colors.red.shade50
                                    : AppColors.blue50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isShort
                                      ? Colors.red.shade300
                                      : AppColors.blue100,
                                ),
                              ),
                              child: Text(
                                isShort
                                    ? 'Thiếu (Tồn $stock/$qty)'
                                    : 'Xuất $qty SP',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isShort
                                      ? Colors.red.shade800
                                      : AppColors.blue800,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: isConfirmedPrepared,
                      onChanged: isExportingInSheet
                          ? null
                          : (val) {
                              setSheetState(
                                () => isConfirmedPrepared = val ?? false,
                              );
                            },
                      title: const Text(
                        'Tôi xác nhận đã chuẩn bị và đóng gói đủ hàng theo phiếu này.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red[700],
                              side: BorderSide(color: Colors.red.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: isExportingInSheet
                                ? null
                                : () {
                                    Navigator.pop(bottomSheetContext);
                                    _showRejectDialog(
                                      defaultReason: shortageItems.isNotEmpty
                                          ? 'Kho không đủ hàng tồn thực tế cho sản phẩm ${shortageItems.first.productName ?? shortageItems.first.productId}'
                                          : 'Kho không đủ hàng tồn thực tế để xuất',
                                    );
                                  },
                            icon: const Icon(Icons.cancel_outlined),
                            label: Text(
                              hasLowStockWarning ? 'HỦY PHIẾU' : 'HỦY',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
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
                            onPressed:
                                (isConfirmedPrepared && !isExportingInSheet)
                                ? () async {
                                    setSheetState(() {
                                      isExportingInSheet = true;
                                      sheetErrorMessage = null;
                                    });
                                    setState(() => _isSubmitting = true);

                                    try {
                                      final updatedReq = await _restockService
                                          .exportRequest(requestId: req.id);
                                      if (!mounted || !context.mounted) return;

                                      setState(() {
                                        _request = updatedReq;
                                        _isSubmitting = false;
                                      });

                                      Navigator.pop(bottomSheetContext);

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Đã xuất kho thành công! Trạng thái phiếu chuyển sang Đang vận chuyển (exported).',
                                          ),
                                          backgroundColor: Colors.green[700],
                                        ),
                                      );
                                      _loadDetail();
                                    } catch (e) {
                                      final formattedError =
                                          formatRestockApiError(e);
                                      if (!mounted || !context.mounted) return;

                                      setState(() => _isSubmitting = false);
                                      setSheetState(() {
                                        isExportingInSheet = false;
                                        sheetErrorMessage = formattedError;
                                      });

                                      if (e is ApiException &&
                                          e.statusCode == 409) {
                                        // Hiển thị dialog báo lỗi HTTP 409 kèm thông điệp từ Backend
                                        showDialog<void>(
                                          context: context,
                                          builder: (dialogContext) => AlertDialog(
                                            icon: const Icon(
                                              Icons.error_outline_rounded,
                                              color: Colors.red,
                                              size: 44,
                                            ),
                                            title: const Text(
                                              'Xuất kho thất bại (409)',
                                            ),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Máy chủ phản hồi xung đột dữ liệu hoặc kho không đủ hàng tồn:',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.muted,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          Colors.red.shade200,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    formattedError,
                                                    style: TextStyle(
                                                      color:
                                                          Colors.red.shade900,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  dialogContext,
                                                ),
                                                child: const Text('Đóng'),
                                              ),
                                            ],
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Xuất kho thất bại: $formattedError',
                                            ),
                                            backgroundColor: Colors.red[700],
                                          ),
                                        );
                                      }
                                    }
                                  }
                                : null,
                            icon: isExportingInSheet
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.unarchive_rounded,
                                    color: Colors.white,
                                  ),
                            label: Text(
                              isExportingInSheet
                                  ? 'ĐANG XUẤT KHO...'
                                  : 'XÁC NHẬN XUẤT KHO NGAY',
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isWarehouseManager) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết phiếu yêu cầu')),
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
                  'Role nhân viên kho (kho) không được truy cập màn hình này.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text('Chi tiết phiếu ${_request?.id ?? widget.requestId}'),
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

    if (_error != null && _request == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
        ),
      );
    }

    final req = _request!;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Card Thông tin phiếu
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
                              color: AppColors.blue50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              req.statusDisplay,
                              style: const TextStyle(
                                color: AppColors.blue800,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Text('Mã phiếu: ${req.id}'),
                      const SizedBox(height: 4),
                      Text('Cửa hàng yêu cầu: ${req.storeName ?? req.storeId}'),
                      const SizedBox(height: 4),
                      Text('Kho nhận: ${req.warehouseName ?? req.warehouseId}'),
                      const SizedBox(height: 4),
                      Text('Thời gian tạo: ${_formatDate(req.createdAt)}'),
                      if (req.createdBy != null) ...[
                        const SizedBox(height: 4),
                        Text('Người tạo: ${req.createdBy}'),
                      ],
                      if (req.approvedBy != null) ...[
                        const SizedBox(height: 4),
                        Text('Người duyệt/xử lý: ${req.approvedBy}'),
                      ],
                      if (req.note != null && req.note!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Ghi chú cửa hàng: ${req.note}',
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Nếu phiếu bị từ chối -> hiển thị lý do
              if (req.isRejected &&
                  req.rejectReason != null &&
                  req.rejectReason!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Card(
                  color: Colors.red.shade50,
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
                            Icon(Icons.cancel_outlined, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Lý do từ chối:',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          req.rejectReason!,
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Danh sách sản phẩm trong phiếu
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Danh sách sản phẩm',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Divider(height: 16),
                      if (req.items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Không có chi tiết sản phẩm nào.'),
                        )
                      else
                        ...req.items.map((item) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              item.productName ?? 'Sản phẩm ${item.productId}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Mã SP: ${item.productId}'
                              '${item.productBarcode != null ? ' · Mã vạch: ${item.productBarcode}' : ''}'
                              '${item.warehouseStock != null ? '\nTồn kho hiện tại: ${item.warehouseStock}' : ''}',
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Cửa hàng yêu cầu: ${item.requestedQuantity}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (item.approvedQuantity != null)
                                  Text(
                                    'Đã duyệt: ${item.approvedQuantity}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Nút Thao tác xử lý phía kho
        if (req.isPending)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                      side: BorderSide(color: Colors.red.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isSubmitting ? null : _showRejectDialog,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text(
                      'TỪ CHỐI',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isSubmitting ? null : _showApproveDialog,
                    icon: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'DUYỆT YÊU CẦU',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (req.isApproved)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                      side: BorderSide(color: Colors.red.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : () => _showRejectDialog(
                            defaultReason: 'Kho không đủ số lượng hàng tồn thực tế để xuất',
                          ),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text(
                      'HỦY PHIẾU',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _showExportDialog,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.unarchive_rounded,
                            color: Colors.white,
                          ),
                    label: Text(
                      _isSubmitting
                          ? 'ĐANG XỬ LÝ...'
                          : 'XUẤT KHO VÀ GỬI CỬA HÀNG',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
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

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/${dt.year} $h:$min';
  }
}
