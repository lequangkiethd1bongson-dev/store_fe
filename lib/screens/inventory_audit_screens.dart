import 'package:flutter/material.dart';
import '../models/inventory_audit_models.dart';
import '../models/product.dart';
import '../state/inventory_audit_controller.dart';
import '../theme/app_theme.dart';

class InventoryAuditMainScreen extends StatefulWidget {
  const InventoryAuditMainScreen({super.key});

  @override
  State<InventoryAuditMainScreen> createState() => _InventoryAuditMainScreenState();
}

class _InventoryAuditMainScreenState extends State<InventoryAuditMainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final InventoryAuditController _controller = InventoryAuditController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _controller.loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo & Kiểm kê Kho (Analytics & Audit)'),
        backgroundColor: AppColors.blue900,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(text: 'Nhập - Xuất - Tồn', icon: Icon(Icons.analytics_outlined)),
            Tab(text: 'Cảnh báo Tối thiểu', icon: Icon(Icons.warning_amber_rounded)),
            Tab(text: 'Kiểm kê Kho', icon: Icon(Icons.checklist_rtl_rounded)),
          ],
        ),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _BalanceReportTab(items: _controller.balanceReport),
              _ReorderAlertsTab(alerts: _controller.reorderAlerts),
              _StocktakeTab(stocktakes: _controller.stocktakes, controller: _controller),
            ],
          );
        },
      ),
    );
  }
}

class _BalanceReportTab extends StatelessWidget {
  const _BalanceReportTab({required this.items});
  final List<InventoryBalanceItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('Chưa có dữ liệu báo cáo Nhập - Xuất - Tồn'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _metricColumn('Đầu kỳ', '${item.openingStock}'),
                    _metricColumn('Nhập (+)', '${item.imported}', Colors.green),
                    _metricColumn('Xuất (-)', '${item.exported}', Colors.orange),
                    _metricColumn('Cuối kỳ', '${item.closingStock}', Colors.blue, isBold: true),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _metricColumn(String label, String value, [Color? color, bool isBold = false]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color ?? Colors.black87)),
      ],
    );
  }
}

class _ReorderAlertsTab extends StatelessWidget {
  const _ReorderAlertsTab({required this.alerts});
  final List<Product> alerts;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 12),
            Text('Tồn kho ổn định, không có sản phẩm dưới mức tối thiểu!', style: TextStyle(fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final product = alerts[index];
        return Card(
          color: Colors.amber.shade50,
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.warning_rounded, color: Colors.amber, size: 36),
            title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Tồn kho hiện tại: ${product.stock} (Dưới mức tối thiểu gợi ý đặt hàng)'),
            trailing: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue900, foregroundColor: Colors.white),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã tạo gợi ý đơn đặt hàng NCC cho ${product.name}')),
                );
              },
              icon: const Icon(Icons.add_shopping_cart, size: 16),
              label: const Text('Đặt hàng'),
            ),
          ),
        );
      },
    );
  }
}

class _StocktakeTab extends StatelessWidget {
  const _StocktakeTab({required this.stocktakes, required this.controller});
  final List<StocktakeRecord> stocktakes;
  final InventoryAuditController controller;

  void _showAddStocktakeDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final systemCtrl = TextEditingController(text: '10');
    final actualCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lập Phiếu Kiểm Kê & Điều Chỉnh Kho'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên sản phẩm')),
              TextField(controller: systemCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Số lượng hệ thống')),
              TextField(controller: actualCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Số lượng thực tế kiểm đếm')),
              TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Ghi chú chênh lệch (Thừa/Thiếu/Hỏng)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue900, foregroundColor: Colors.white),
            onPressed: () async {
              final actual = int.tryParse(actualCtrl.text) ?? 0;
              final system = int.tryParse(systemCtrl.text) ?? 0;
              final record = StocktakeRecord(
                productId: DateTime.now().millisecondsSinceEpoch % 10000,
                productName: nameCtrl.text.isEmpty ? 'Sản phẩm kiểm kê' : nameCtrl.text,
                systemQuantity: system,
                actualQuantity: actual,
                differenceQuantity: actual - system,
                note: noteCtrl.text,
                createdBy: 'Quản lý kho',
              );
              await controller.addStocktake(record);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Lưu phiếu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.blue900,
        foregroundColor: Colors.white,
        onPressed: () => _showAddStocktakeDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Tạo Phiếu Kiểm Kê'),
      ),
      body: stocktakes.isEmpty
          ? const Center(child: Text('Chưa có phiếu kiểm kê định kỳ nào được tạo'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: stocktakes.length,
              itemBuilder: (context, index) {
                final st = stocktakes[index];
                final isSurplus = st.differenceQuantity > 0;
                final isDeficit = st.differenceQuantity < 0;
                final diffColor = isSurplus ? Colors.green : (isDeficit ? Colors.red : Colors.grey);
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(st.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Chip(
                              backgroundColor: diffColor.withValues(alpha: 0.1),
                              label: Text(
                                'Chênh lệch: ${st.differenceQuantity >= 0 ? '+' : ''}${st.differenceQuantity}',
                                style: TextStyle(color: diffColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('SL Hệ thống: ${st.systemQuantity} | SL Thực tế: ${st.actualQuantity}'),
                        if (st.note != null && st.note!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Ghi chú: ${st.note}', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
