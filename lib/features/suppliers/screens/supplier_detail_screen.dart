import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../models/supplier.dart';
import '../state/supplier_controller.dart';
import '../widgets/supplier_status_badge.dart';
import 'supplier_form_screen.dart';

class SupplierDetailScreen extends StatefulWidget {
  const SupplierDetailScreen({
    required this.supplierId,
    required this.controller,
    required this.userRole,
    this.initialSupplier,
    super.key,
  });

  final String supplierId;
  final SupplierController controller;
  final String userRole;
  final Supplier? initialSupplier;

  @override
  State<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends State<SupplierDetailScreen> {
  Supplier? _supplier;

  bool get _isAdmin => widget.userRole.trim().toUpperCase() == 'ADMIN';

  @override
  void initState() {
    super.initState();
    _supplier = widget.initialSupplier;
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    await widget.controller.fetchSupplierById(widget.supplierId);
    if (!mounted) return;
    setState(() {
      _supplier = widget.controller.selectedSupplier ?? _supplier;
    });
  }

  Future<void> _handleToggleStatus() async {
    final supp = _supplier;
    if (supp == null) return;

    final targetIsActive = !supp.isActive;
    final actionText = targetIsActive ? 'Kích hoạt lại' : 'Ngừng hoạt động';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Xác nhận $actionText'),
        content: Text(
          targetIsActive
              ? 'Nhà cung cấp "${supp.name}" sẽ được phép chọn khi lập phiếu nhập mới.'
              : 'Nhà cung cấp "${supp.name}" sẽ chuyển sang trạng thái Tạm ngưng và không thể chọn khi lập phiếu nhập hàng mới.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: targetIsActive
                  ? Colors.green[700]
                  : Colors.red[700],
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              actionText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await widget.controller.toggleSupplierActive(
      supp.id,
      supp.isActive,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã $actionText nhà cung cấp "${supp.name}".'),
          backgroundColor: targetIsActive
              ? Colors.green[700]
              : Colors.orange[800],
        ),
      );
      setState(() {
        _supplier = widget.controller.selectedSupplier ?? _supplier;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.error ?? 'Đổi trạng thái không thành công.',
          ),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final supp = _supplier ?? widget.controller.selectedSupplier;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(supp?.name ?? 'Chi tiết nhà cung cấp'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _loadDetail,
            icon: const Icon(Icons.refresh_rounded),
          ),
          if (_isAdmin && supp != null)
            IconButton(
              tooltip: 'Chỉnh sửa',
              onPressed: () async {
                final updated = await Navigator.of(context).push<Supplier>(
                  MaterialPageRoute(
                    builder: (_) => SupplierFormScreen(
                      controller: widget.controller,
                      supplier: supp,
                    ),
                  ),
                );
                if (updated != null) {
                  setState(() => _supplier = updated);
                }
              },
              icon: const Icon(Icons.edit_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            if (widget.controller.isLoading && supp == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (supp == null) {
              return Center(
                child: Text(
                  widget.controller.error ??
                      'Không tìm thấy thông tin nhà cung cấp.',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
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
                            Expanded(
                              child: Text(
                                supp.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            SupplierStatusBadge(isActive: supp.isActive),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildDetailRow('Mã NCC', supp.id),
                        _buildDetailRow(
                          'Số điện thoại',
                          supp.phone ?? 'Chưa có',
                        ),
                        _buildDetailRow('Địa chỉ', supp.address ?? 'Chưa có'),
                        _buildDetailRow('Email', supp.email ?? 'Chưa có'),
                        if (supp.fax != null && supp.fax!.isNotEmpty)
                          _buildDetailRow('Fax', supp.fax!),
                      ],
                    ),
                  ),
                ),
                if (_isAdmin) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () async {
                            final updated = await Navigator.of(context)
                                .push<Supplier>(
                                  MaterialPageRoute(
                                    builder: (_) => SupplierFormScreen(
                                      controller: widget.controller,
                                      supplier: supp,
                                    ),
                                  ),
                                );
                            if (updated != null) {
                              setState(() => _supplier = updated);
                            }
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text(
                            'SỬA THÔNG TIN',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: supp.isActive
                                ? Colors.red[700]
                                : Colors.green[700],
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: widget.controller.isSaving
                              ? null
                              : _handleToggleStatus,
                          icon: Icon(
                            supp.isActive
                                ? Icons.block_rounded
                                : Icons.check_circle_rounded,
                            color: Colors.white,
                          ),
                          label: Text(
                            supp.isActive ? 'NGỪNG HĐ' : 'KÍCH HOẠT LẠI',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
