import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../models/supplier.dart';
import '../state/supplier_controller.dart';
import '../widgets/supplier_card.dart';
import '../widgets/supplier_search_bar.dart';
import 'supplier_detail_screen.dart';
import 'supplier_form_screen.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({
    required this.userRole,
    this.controller,
    super.key,
  });

  final String userRole;
  final SupplierController? controller;

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  late final SupplierController _controller;
  late final bool _ownsController;

  String get _cleanRole => widget.userRole.trim().toUpperCase();

  bool get _isAdmin => _cleanRole == 'ADMIN';

  bool get _isWarehouseRole =>
      _isAdmin ||
      _cleanRole == 'WAREHOUSE_MANAGER' ||
      _cleanRole == 'KHO_MANAGER' ||
      _cleanRole == 'KHO_QUAN_LY' ||
      _cleanRole == 'QUAN_LY_KHO' ||
      _cleanRole == 'WAREHOUSE_STAFF' ||
      _cleanRole == 'KHO' ||
      _cleanRole == 'KHO_STAFF';

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? SupplierController();
    _ownsController = widget.controller == null;

    if (_isWarehouseRole) {
      _controller.fetchSuppliers(activeOnly: !_isAdmin);
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isWarehouseRole) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quản lý nhà cung cấp')),
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
                  'Tài khoản cửa hàng hoặc bán hàng không được phép truy cập chức năng Quản lý nhà cung cấp.',
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
        title: Text(
          _isAdmin ? 'Quản lý nhà cung cấp' : 'Danh sách nhà cung cấp',
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: () => _controller.fetchSuppliers(activeOnly: !_isAdmin),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.blue700,
              onPressed: () async {
                final newSupp = await Navigator.of(context).push<Supplier>(
                  MaterialPageRoute(
                    builder: (_) => SupplierFormScreen(controller: _controller),
                  ),
                );
                if (newSupp != null) {
                  _controller.fetchSuppliers(activeOnly: false);
                }
              },
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'THÊM NCC MỚI',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final filtered = _controller.filteredSuppliers;
            final isLoading = _controller.isLoading;
            final error = _controller.error;
            final totalCount = filtered.length;
            final activeCount = filtered.where((s) => s.isActive).length;
            final inactiveCount = totalCount - activeCount;

            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.blue900, AppColors.blue700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blue900.withValues(alpha: 0.14),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.business_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ĐỐI TÁC CUNG ỨNG SSM4',
                              style: TextStyle(
                                color: Color(0xFFFFD58A),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$totalCount Nhà cung cấp hiển thị',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Đang hợp tác: $activeCount • Tạm ngưng: $inactiveCount',
                              style: const TextStyle(
                                color: Color(0xFFDCEBFA),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SupplierSearchBar(
                  searchQuery: _controller.searchQuery,
                  onSearchChanged: (query) {
                    _controller.setSearchQuery(query);
                    _controller.fetchSuppliers(activeOnly: !_isAdmin);
                  },
                  statusFilter: _controller.statusFilter,
                  onFilterChanged: (filter) {
                    _controller.setStatusFilter(filter);
                    _controller.fetchSuppliers(activeOnly: !_isAdmin);
                  },
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () =>
                        _controller.fetchSuppliers(activeOnly: !_isAdmin),
                    child: _buildListContent(filtered, isLoading, error),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildListContent(
    List<Supplier> filtered,
    bool isLoading,
    String? error,
  ) {
    if (isLoading && filtered.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && filtered.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.error_outline_rounded, size: 56, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.red),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: () =>
                  _controller.fetchSuppliers(activeOnly: !_isAdmin),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ),
        ],
      );
    }

    if (filtered.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: const [
          Icon(Icons.business_outlined, size: 64, color: AppColors.muted),
          SizedBox(height: 16),
          Text(
            'Không tìm thấy nhà cung cấp nào.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final supplier = filtered[index];
        return SupplierCard(
          supplier: supplier,
          showActions: _isAdmin,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SupplierDetailScreen(
                  supplierId: supplier.id,
                  controller: _controller,
                  userRole: widget.userRole,
                  initialSupplier: supplier,
                ),
              ),
            );
          },
          onEdit: _isAdmin
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SupplierFormScreen(
                        controller: _controller,
                        supplier: supplier,
                      ),
                    ),
                  );
                }
              : null,
          onToggleStatus: _isAdmin
              ? () async {
                  await _controller.toggleSupplierActive(
                    supplier.id,
                    supplier.isActive,
                  );
                }
              : null,
        );
      },
    );
  }
}
