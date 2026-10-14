import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/store_models.dart';
import '../state/staff_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

/// cung cấp không gian làm việc riêng cho các thao tác của nhân viên.
class StaffWorkspace extends StatefulWidget {
  const StaffWorkspace({
    required this.controller,
    required this.staffName,
    required this.onExit,
    super.key,
  });

  final StaffController controller;
  final String staffName;
  final VoidCallback onExit;

  /// tạo đối tượng trạng thái để ghi nhớ tab nhân viên đang mở.
  @override
  State<StaffWorkspace> createState() => _StaffWorkspaceState();
}

class _StaffWorkspaceState extends State<StaffWorkspace> {
  int _selectedTab = 0;

  static const _titles = ['Sơ đồ', 'Kho hàng', 'Bán hàng', 'Chấm công'];

  /// dựng nội dung tab nhân viên và thanh điều hướng bốn chức năng.
  @override
  Widget build(BuildContext context) {
    final pages = [
      _StaffDashboard(
        controller: widget.controller,
        onOpenTab: (index) => setState(() => _selectedTab = index),
      ),
      _StaffInventoryScreen(controller: widget.controller),
      _StaffSalesScreen(controller: widget.controller),
      _StaffAttendanceScreen(staffName: widget.staffName),
    ];
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(_titles[_selectedTab]),
        leading: IconButton(
          key: const ValueKey('staff-exit'),
          tooltip: 'Thoát giao diện nhân viên',
          onPressed: widget.onExit,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.blue50,
              child: Text(
                widget.staffName.isEmpty
                    ? 'NV'
                    : widget.staffName.characters.first.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.blue800,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _selectedTab, children: pages),
      bottomNavigationBar: NavigationBar(
        key: const ValueKey('staff-navigation'),
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Sơ đồ',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Kho hàng',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale_rounded),
            label: 'Bán hàng',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule_rounded),
            label: 'Chấm công',
          ),
        ],
      ),
    );
  }
}

class _StaffDashboard extends StatefulWidget {
  const _StaffDashboard({required this.controller, required this.onOpenTab});

  final StaffController controller;
  final ValueChanged<int> onOpenTab;

  @override
  State<_StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<_StaffDashboard> {
  String _searchText = '';

  /// tổng hợp số liệu tồn và lối tắt tới sơ đồ, kho, bán hàng.
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final matchingProducts = _searchText.trim().isEmpty
            ? const <Product>[]
            : controller.products
                  .where(
                    (product) => product.name.toLowerCase().contains(
                      _searchText.trim().toLowerCase(),
                    ),
                  )
                  .toList(growable: false);
        return ListView(
        key: const ValueKey('staff-dashboard'),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.blue900, AppColors.blue700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue900.withValues(alpha: 0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'VẬN HÀNH CỬA HÀNG',
                  style: TextStyle(
                    color: Color(0xFFCBE4FF),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Chào ca làm việc mới!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Quản lý kệ, nhập kho và bán hàng tại một nơi.',
                  style: TextStyle(color: Color(0xFFDCEBFA), fontSize: 11),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _DashboardMetric(
                        label: 'Sản phẩm trên kệ',
                        value: '${controller.shelfItemCount}',
                        icon: Icons.storefront_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DashboardMetric(
                        label: 'Trong kho',
                        value: '${controller.warehouseItemCount}',
                        icon: Icons.inventory_2_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  key: const ValueKey('staff-quick-inventory'),
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'Nhập / chuyển kho',
                  subtitle: 'Quét mã sản phẩm',
                  tint: AppColors.blue50,
                  onTap: () => widget.onOpenTab(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  key: const ValueKey('staff-quick-sale'),
                  icon: Icons.point_of_sale_rounded,
                  title: 'Tạo hóa đơn',
                  subtitle: 'Quét sản phẩm bán',
                  tint: const Color(0xFFEAF8F3),
                  onTap: () => widget.onOpenTab(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Khu vực trưng bày',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: () => widget.onOpenTab(0),
                child: const Text('9 kệ'),
              ),
            ],
          ),
          const Text(
            'Tìm tên sản phẩm để đến đúng kệ hoặc chọn một kệ trên sơ đồ.',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('staff-shelf-search'),
            onChanged: (value) => setState(() => _searchText = value),
            decoration: const InputDecoration(
              hintText: 'Tìm tên sản phẩm trên kệ',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          if (matchingProducts.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...matchingProducts.map((product) {
              final location = controller.locationForProduct(product.id);
              return Card(
                margin: const EdgeInsets.only(bottom: 5),
                child: ListTile(
                  key: ValueKey('staff-shelf-search-result-${product.id}'),
                  dense: true,
                  leading: const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.blue700,
                  ),
                  title: Text(product.name),
                  subtitle: Text(
                    location == null
                        ? 'Chưa được trưng bày trên kệ'
                        : 'Kệ ${location.shelfCode} · tầng ${location.tier}',
                  ),
                  onTap: location == null
                      ? null
                      : () => _openShelf(
                          context,
                          controller,
                          StaffController.shelfList.firstWhere(
                            (shelf) => shelf.code == location.shelfCode,
                          ),
                          highlightProductId: product.id,
                          highlightTier: location.tier,
                        ),
                ),
              );
            }),
          ],
          const SizedBox(height: 13),
          GridView.builder(
            itemCount: StaffController.shelfList.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.94,
            ),
            itemBuilder: (context, index) {
              final shelf = StaffController.shelfList[index];
              return _ShelfMapCard(
                shelf: shelf,
                fillPercent: controller.getShelfFillPercent(shelf.code),
                lowStockCount: controller.lowStockLines(shelf.code).length,
                onTap: () => _openShelf(context, controller, shelf),
              );
            },
          ),
          const SizedBox(height: 14),
          const _ShelfLegend(),
        ],
        );
      },
    );
  }
}

class _DashboardMetric extends StatelessWidget {
  const _DashboardMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  /// hiển thị một chỉ số kho cùng biểu tượng minh họa.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFDCEBFA), fontSize: 8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;
  final VoidCallback onTap;

  /// tạo thẻ thao tác nhanh để chuyển tới chức năng nhân viên.
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: tint,
                child: Icon(icon, color: AppColors.blue700, size: 21),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.muted, fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShelfMapCard extends StatelessWidget {
  const _ShelfMapCard({
    required this.shelf,
    required this.fillPercent,
    required this.lowStockCount,
    required this.onTap,
  });

  final StaffShelf shelf;
  final int fillPercent;
  final int lowStockCount;
  final VoidCallback onTap;

  /// vẽ một kệ trên sơ đồ cùng mức chứa và trạng thái hiện tại.
  @override
  Widget build(BuildContext context) {
    final isLow = fillPercent < 35;
    final accent = isLow ? const Color(0xFFE69A4D) : AppColors.blue600;
    final fill = isLow ? const Color(0xFFFFF8F0) : const Color(0xFFF2FAFC);
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: ValueKey('staff-shelf-${shelf.code}'),
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.grid_view_rounded, color: accent, size: 19),
              ),
              const Spacer(),
              Text(
                'Kệ ${shelf.code}',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                shelf.category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 8),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fillPercent / 100,
                  minHeight: 4,
                  backgroundColor: const Color(0xFFDDE7ED),
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$fillPercent% đầy',
                style: TextStyle(
                  color: accent,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (lowStockCount > 0) ...[
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFD83D4D),
                      size: 13,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        '$lowStockCount tầng sắp hết',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFD83D4D),
                          fontSize: 7,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ShelfLegend extends StatelessWidget {
  const _ShelfLegend();

  /// giải thích ý nghĩa màu sắc được dùng trong sơ đồ kệ.
  @override
  Widget build(BuildContext context) {
    return const Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      children: [
        _LegendDot(color: AppColors.blue600, label: 'Còn nhiều'),
        _LegendDot(color: Color(0xFFE69A4D), label: 'Sắp hết'),
        _LegendDot(color: Color(0xFF877BEA), label: 'Cần kiểm tra'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  /// hiển thị chấm màu cạnh một nhãn trạng thái.
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 8),
        ),
      ],
    );
  }
}

/// mở trang chi tiết cho kệ được nhân viên chọn.
Future<void> _openShelf(
  BuildContext context,
  StaffController controller,
  StaffShelf shelf,
  {String? highlightProductId, int? highlightTier}
) => Navigator.of(context).push<void>(
  MaterialPageRoute<void>(
    builder: (_) => StaffShelfDetailScreen(
      controller: controller,
      shelf: shelf,
      highlightProductId: highlightProductId,
      highlightTier: highlightTier,
    ),
  ),
);

/// trình bày hàng hóa, tầng kệ và các thao tác kiểm tra tồn.
class StaffShelfDetailScreen extends StatefulWidget {
  const StaffShelfDetailScreen({
    required this.controller,
    required this.shelf,
    this.highlightProductId,
    this.highlightTier,
    super.key,
  });

  final StaffController controller;
  final StaffShelf shelf;
  final String? highlightProductId;
  final int? highlightTier;

  @override
  State<StaffShelfDetailScreen> createState() =>
      _StaffShelfDetailScreenState();
}

class _StaffShelfDetailScreenState extends State<StaffShelfDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _highlightAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );

  @override
  void initState() {
    super.initState();
    if (widget.highlightTier != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _highlightAnimation.repeat(reverse: true, count: 6).then((_) {
            if (mounted) _highlightAnimation.value = 0;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _highlightAnimation.dispose();
    super.dispose();
  }

  /// dựng chi tiết kệ và cho phép quét sản phẩm hoặc chuyển hàng lên kệ.
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final shelf = widget.shelf;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final lines = controller.shelfLines(shelf.code);
        final count = lines.fold(0, (sum, line) => sum + line.quantity);
        return Scaffold(
          appBar: AppBar(
            title: Text('Chi tiết Kệ ${shelf.code}'),
            actions: [
              IconButton(
                tooltip: 'Mã QR của kệ ${shelf.code}',
                onPressed: () => _showShelfCode(context, shelf),
                icon: const Icon(Icons.qr_code_2_rounded),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.qr_code_2_rounded,
                        color: AppColors.blue900,
                        size: 47,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shelf.category.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.blue700,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'SH-${shelf.code}-2024-001',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF4BAE81),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _ShelfStat(title: 'Sức chứa', value: '${shelf.capacity} SP'),
                  _ShelfStat(title: 'Hiện có', value: '$count SP'),
                  _ShelfStat(title: 'Cập nhật', value: 'Vừa xong', last: true),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.blue900,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'KỆ ${shelf.code}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${lines.length} loại · $count sản phẩm',
                      style: const TextStyle(color: Colors.white, fontSize: 9),
                    ),
                  ],
                ),
              ),
              for (
                var tier = 1;
                tier <= StaffController.shelfTierCount;
                tier++
              )
                _ShelfProductRow(
                  key: ValueKey('shelf-tier-${shelf.code}-$tier'),
                  tier: tier,
                  line: controller.shelfTierLines(shelf.code, tier).firstOrNull,
                  isHighlighted: widget.highlightTier == tier,
                  pulse: widget.highlightTier == tier
                      ? _highlightAnimation
                      : null,
                  onScan: () =>
                      _moveStockToShelf(context, controller, shelf, tier),
                  onLowStockTap: () {
                    final line = controller
                        .shelfTierLines(shelf.code, tier)
                        .firstOrNull;
                    if (line != null &&
                        line.quantity < StaffController.lowStockThreshold) {
                      _showLowStockDetails(context, shelf, tier, line);
                    }
                  },
                ),
              const SizedBox(height: 15),
            ],
          ),
        );
      },
    );
  }
}

class _ShelfStat extends StatelessWidget {
  const _ShelfStat({
    required this.title,
    required this.value,
    this.last = false,
  });

  final String title;
  final String value;
  final bool last;

  /// hiển thị một con số thống kê của kệ.
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.horizontal(
            left: Radius.circular(last ? 0 : 15),
            right: Radius.circular(last ? 15 : 0),
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(color: AppColors.muted, fontSize: 8),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShelfProductRow extends StatelessWidget {
  const _ShelfProductRow({
    required this.tier,
    required this.line,
    required this.onScan,
    required this.onLowStockTap,
    this.isHighlighted = false,
    this.pulse,
    super.key,
  });

  final int tier;
  final CartLine? line;
  final VoidCallback onScan;
  final VoidCallback onLowStockTap;
  final bool isHighlighted;
  final Animation<double>? pulse;

  /// trình bày sản phẩm trên một tầng kệ và nút kiểm tra số lượng.
  @override
  Widget build(BuildContext context) {
    final hasLowStock =
        line != null && line!.quantity < StaffController.lowStockThreshold;
    final row = Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: line == null ? const Color(0xFFF8FAFD) : Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.blue900.withValues(alpha: 0.12)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.blue50,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              'Tầng\n$tier',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.blue800,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 9),
          if (line == null)
            Container(
              width: 62,
              height: 65,
              decoration: BoxDecoration(
                color: AppColors.blue50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.shelves,
                color: AppColors.muted,
                size: 28,
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 62,
                height: 65,
                child: ProductImage(
                  imageUrl: line!.product.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: line == null
                ? const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kệ trống',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Quét sản phẩm để xếp hàng vào tầng này',
                        style: TextStyle(color: AppColors.muted, fontSize: 8),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line!.product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${line!.product.packageSize ?? 'Chưa rõ quy cách'} · ${line!.product.brand ?? 'Chưa có thương hiệu'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Còn lại: ${line!.quantity} sản phẩm',
                        style: TextStyle(
                          color: hasLowStock
                              ? const Color(0xFFD83D4D)
                              : AppColors.blue700,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasLowStock)
                IconButton(
                  key: ValueKey('shelf-low-stock-$tier'),
                  tooltip: 'Xem cảnh báo hàng sắp hết',
                  visualDensity: VisualDensity.compact,
                  onPressed: onLowStockTap,
                  icon: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFD83D4D),
                  ),
                ),
              IconButton.filledTonal(
                tooltip: line == null ? 'Quét hàng vào tầng $tier' : 'Quét thêm hàng',
                onPressed: onScan,
                icon: const Icon(Icons.document_scanner_outlined, size: 19),
              ),
            ],
          ),
        ],
      ),
    );
    if (!isHighlighted || pulse == null) return row;
    return AnimatedBuilder(
      animation: pulse!,
      child: row,
      builder: (context, child) {
        final emphasis = pulse!.value;
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.blue600.withValues(alpha: 0.25 + emphasis * 0.75),
              width: 1 + emphasis * 2,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.blue600.withValues(alpha: emphasis * 0.2),
                blurRadius: 14,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}

class _StaffInventoryScreen extends StatefulWidget {
  const _StaffInventoryScreen({required this.controller});

  final StaffController controller;

  @override
  State<_StaffInventoryScreen> createState() => _StaffInventoryScreenState();
}

class _StaffInventoryScreenState extends State<_StaffInventoryScreen> {
  String _searchText = '';

  /// dựng tồn kho và các thao tác nhập hoặc chuyển hàng lên kệ.
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final query = _searchText.trim().toLowerCase();
        final products = controller.products
            .where(
              (product) =>
                  product.name.toLowerCase().contains(query) ||
                  product.category.toLowerCase().contains(query) ||
                  (product.brand?.toLowerCase().contains(query) ?? false),
            )
            .toList(growable: false);
        return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _InventorySummary(controller: controller),
          const SizedBox(height: 14),
          FilledButton.icon(
            key: const ValueKey('inventory-scan-receive'),
            onPressed: () => _receiveStock(context, controller),
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('Quét mã vạch nhập kho'),
          ),
          const SizedBox(height: 9),
          const SizedBox(height: 20),
          const Text(
            'Sản phẩm trong kho',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('staff-inventory-search'),
            onChanged: (value) => setState(() => _searchText = value),
            decoration: const InputDecoration(
              hintText: 'Tìm tên, nhóm hàng hoặc thương hiệu',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 10),
          ...products.map(
            (product) => _InventoryProductCard(
              key: ValueKey('inventory-product-${product.id}'),
              controller: controller,
              product: product,
              onTap: () => _showInventoryProductDetails(
                context,
                controller,
                product,
              ),
            ),
          ),
        ],
        );
      },
    );
  }
}

class _InventorySummary extends StatelessWidget {
  const _InventorySummary({required this.controller});

  final StaffController controller;

  /// tóm tắt tổng số hàng và số lượt nhập kho.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.blue50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.blue100),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 23,
            backgroundColor: Colors.white,
            child: Icon(Icons.inventory_2_rounded, color: AppColors.blue700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tổng sản phẩm trong kho',
                  style: TextStyle(color: AppColors.muted, fontSize: 10),
                ),
                const SizedBox(height: 4),
                Text(
                  '${controller.warehouseItemCount} sản phẩm',
                  style: const TextStyle(
                    color: AppColors.blue900,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${controller.intakeCount} lần nhập',
            style: const TextStyle(color: AppColors.blue700, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _InventoryProductCard extends StatelessWidget {
  const _InventoryProductCard({
    required this.controller,
    required this.product,
    required this.onTap,
    super.key,
  });

  final StaffController controller;
  final Product product;
  final VoidCallback onTap;

  /// hiển thị ảnh, mã vạch và số lượng tồn của một sản phẩm trong kho.
  @override
  Widget build(BuildContext context) {
    final quantity = controller.warehouseQuantity(product.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 58,
              height: 58,
              child: ProductImage(imageUrl: product.imageUrl),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mã: ${StaffController.barcodeByProductId[product.id]}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 8),
                ),
                const SizedBox(height: 4),
                Text(
                  product.category,
                  style: const TextStyle(color: AppColors.muted, fontSize: 9),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$quantity',
                style: const TextStyle(
                  color: AppColors.blue800,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'trong kho',
                style: TextStyle(color: AppColors.muted, fontSize: 8),
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

/// mở thông tin cơ bản và lịch sử ngày nhập của sản phẩm trong kho.
Future<void> _showInventoryProductDetails(
  BuildContext context,
  StaffController controller,
  Product product,
) async {
  final receipts = controller.receiptsForProduct(product.id).reversed.toList();
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              product.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text('Thương hiệu: ${product.brand ?? 'Chưa có thông tin'}'),
            Text('Dung tích / quy cách: ${product.packageSize ?? 'Chưa có thông tin'}'),
            Text('Nhóm hàng: ${product.category}'),
            Text('Mã vạch: ${product.barcode ?? 'Chưa có mã'}'),
            const SizedBox(height: 8),
            Text(
              'Còn trong kho: ${controller.warehouseQuantity(product.id)} sản phẩm',
              style: const TextStyle(
                color: AppColors.blue800,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Divider(height: 24),
            const Text(
              'Lịch sử nhập kho',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            if (receipts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Chưa có lần nhập kho nào được ghi nhận.'),
              )
            else
              ...receipts.map(
                (receipt) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.event_available_outlined,
                    color: AppColors.blue700,
                  ),
                  title: Text(_formatStaffDate(receipt.receivedAt)),
                  subtitle: Text('Nhập ${receipt.quantity} sản phẩm'),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// đổi thời điểm nhập hàng thành ngày giờ dễ đọc trong giao diện.
String _formatStaffDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month/${date.year} · $hour:$minute';
}

class _StaffSalesScreen extends StatelessWidget {
  const _StaffSalesScreen({required this.controller});

  final StaffController controller;

  /// dựng màn bán hàng, hóa đơn nháp và tổng thanh toán.
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final lines = controller.saleLines;
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                children: [
                  Container(
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.blue900, AppColors.blue700],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.point_of_sale_rounded,
                          color: Colors.white,
                          size: 27,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quầy thanh toán',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Quét mã sản phẩm để lập hóa đơn',
                                style: TextStyle(
                                  color: Color(0xFFDCEBFA),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 13),
                  FilledButton.icon(
                    key: const ValueKey('sales-scan-product'),
                    onPressed: () => _scanSaleProduct(context, controller),
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('Quét mã vạch sản phẩm'),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Hóa đơn hiện tại',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (lines.isNotEmpty)
                        TextButton(
                          onPressed: controller.clearSale,
                          child: const Text('Xóa hóa đơn'),
                        ),
                    ],
                  ),
                  if (lines.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.qr_code_scanner_rounded,
                            color: AppColors.blue600,
                            size: 38,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Chưa có sản phẩm',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Quét mã sản phẩm khách hàng mang ra quầy.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...lines.map(
                      (line) => _SaleLine(
                        key: ValueKey('sale-line-${line.product.id}'),
                        line: line,
                        onRemove: () =>
                            controller.setSaleQuantity(line.product, 0),
                        onIncrement: () =>
                            _incrementSaleLine(context, controller, line),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Tổng thanh toán',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Text(
                        formatVnd(controller.saleTotal),
                        key: const ValueKey('sales-total'),
                        style: const TextStyle(
                          color: AppColors.blue800,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const ValueKey('sales-print-invoice'),
                          onPressed: lines.isEmpty
                              ? null
                              : () => _completeAndPreview(context, controller),
                          icon: const Icon(Icons.print_outlined),
                          label: const Text('In hóa đơn'),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: FilledButton(
                          onPressed: lines.isEmpty
                              ? null
                              : () => _completeAndPreview(context, controller),
                          child: const Text('Thanh toán'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SaleLine extends StatelessWidget {
  const _SaleLine({
    required this.line,
    required this.onRemove,
    required this.onIncrement,
    super.key,
  });

  final CartLine line;
  final VoidCallback onRemove;
  final VoidCallback onIncrement;

  /// hiển thị một sản phẩm trong hóa đơn cùng thao tác điều chỉnh.
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: SizedBox(
              width: 51,
              height: 51,
              child: ProductImage(imageUrl: line.product.imageUrl),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatVnd(line.product.price)} × ${line.quantity}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 9),
                ),
              ],
            ),
          ),
          Text(
            formatVnd(line.total),
            style: const TextStyle(
              color: AppColors.blue800,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Điều chỉnh sản phẩm',
            onSelected: (value) {
              if (value == 'remove') onRemove();
              if (value == 'add') onIncrement();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'add', child: Text('Tăng số lượng')),
              PopupMenuItem(value: 'remove', child: Text('Xóa khỏi hóa đơn')),
            ],
          ),
        ],
      ),
    );
  }
}

class _StaffAttendanceScreen extends StatelessWidget {
  const _StaffAttendanceScreen({required this.staffName});

  final String staffName;

  /// hiển thị trang chấm công mẫu đang chờ kết nối dữ liệu thật.
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(21),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.blue900, AppColors.blue700],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.access_time_filled_rounded,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(height: 14),
              Text(
                'Xin chào, $staffName',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${now.day}/${now.month}/${now.year}',
                style: const TextStyle(color: Color(0xFFDCEBFA), fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Card(
          child: ListTile(
            leading: const Icon(
              Icons.schedule_rounded,
              color: AppColors.blue700,
            ),
            title: const Text(
              'Chấm công',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'Giao diện chấm công sẽ được bổ sung sau.',
              style: TextStyle(fontSize: 10),
            ),
            trailing: const Icon(Icons.lock_clock_outlined),
          ),
        ),
      ],
    );
  }
}

/// mở giao diện camera quét mã và trả về sản phẩm nhận diện được.
Future<Product?> _showBarcodeScanner(
  BuildContext context,
  StaffController controller,
) => Navigator.of(context).push<Product>(
  MaterialPageRoute<Product>(
    builder: (_) => _BarcodeScannerScreen(controller: controller),
  ),
);

class _BarcodeScannerScreen extends StatefulWidget {
  const _BarcodeScannerScreen({required this.controller});

  final StaffController controller;

  @override
  State<_BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<_BarcodeScannerScreen> {
  late final MobileScannerController _cameraController =
      MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        formats: const [
          BarcodeFormat.ean13,
          BarcodeFormat.ean8,
          BarcodeFormat.upcA,
          BarcodeFormat.upcE,
          BarcodeFormat.code128,
          BarcodeFormat.code39,
          BarcodeFormat.qrCode,
        ],
      );
  final _textController = TextEditingController();
  String? _errorMessage;
  bool _hasResolvedCode = false;

  @override
  void dispose() {
    _cameraController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét mã sản phẩm'),
        actions: [
          IconButton(
            key: const ValueKey('staff-scanner-flash'),
            tooltip: 'Bật hoặc tắt đèn',
            onPressed: _cameraController.toggleTorch,
            icon: const Icon(Icons.flashlight_on_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _cameraController,
                    onDetect: _onBarcodeDetected,
                    errorBuilder: (context, error) => ColoredBox(
                      color: AppColors.ink,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Không thể mở camera: ${error.errorCode.name}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: Center(
                      child: Container(
                        width: MediaQuery.sizeOf(context).width * 0.78,
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 3),
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 20,
                    right: 20,
                    bottom: 18,
                    child: Text(
                      'Đưa mã vạch trên bao bì vào khung quét',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                14,
                18,
                MediaQuery.viewInsetsOf(context).bottom + 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Có thể nhập mã nếu camera không quét được.',
                    style: TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const ValueKey('staff-barcode-input'),
                    controller: _textController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Mã vạch',
                      prefixIcon: const Icon(Icons.numbers_rounded),
                      errorText: _errorMessage,
                    ),
                    onSubmitted: (_) => _resolveBarcode(_textController.text),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    key: const ValueKey('staff-barcode-confirm'),
                    onPressed: () => _resolveBarcode(_textController.text),
                    child: const Text('Xác nhận mã'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// đọc kết quả camera và chuyển mã vạch đã nhận diện sang tra cứu sản phẩm.
  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_hasResolvedCode) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.isNotEmpty) {
        _resolveBarcode(value);
        return;
      }
    }
  }

  /// tìm sản phẩm theo mã vừa quét hoặc mã nhập tay rồi trả kết quả về.
  Future<void> _resolveBarcode(String barcode) async {
    if (_hasResolvedCode) return;
    final product = widget.controller.productFromBarcode(barcode);
    if (product == null) {
      setState(
        () => _errorMessage =
            'Chưa tìm thấy sản phẩm gắn với mã ${barcode.trim()}.',
      );
      return;
    }
    _hasResolvedCode = true;
    await _cameraController.stop();
    if (mounted) Navigator.of(context).pop(product);
  }
}

/// hỏi số lượng sản phẩm và trả về giá trị đã xác nhận.
Future<int?> _askQuantity(
  BuildContext context, {
  required String title,
  Product? product,
  int initial = 1,
}) async {
  var quantityText = '$initial';
  return showDialog<int>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product != null) ...[
              Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              Text(
                '${product.packageSize ?? 'Chưa rõ quy cách'} · ${product.brand ?? 'Chưa có thương hiệu'}',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 14),
            ],
            TextFormField(
              key: const ValueKey('staff-quantity-input'),
              initialValue: '$initial',
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số lượng sản phẩm',
                prefixIcon: Icon(Icons.numbers_rounded),
              ),
              onChanged: (value) => setDialogState(() => quantityText = value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            key: const ValueKey('staff-quantity-confirm'),
            onPressed: () {
              final value = int.tryParse(quantityText.trim());
              if (value == null || value <= 0) return;
              Navigator.pop(dialogContext, value);
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    ),
  );
}

/// chạy luồng quét mẫu, nhập số lượng rồi cộng hàng vào kho.
Future<void> _receiveStock(
  BuildContext context,
  StaffController controller,
) async {
  final product = await _showBarcodeScanner(context, controller);
  if (product == null || !context.mounted) return;
  final quantity = await _askQuantity(
    context,
    title: 'Nhập sản phẩm vào kho',
    product: product,
  );
  if (quantity == null || !context.mounted) return;
  controller.receiveStock(product, quantity);
  showSmartMartNotice(
    context,
    message: 'Đã nhập $quantity ${product.name} vào kho',
    icon: Icons.inventory_2_outlined,
  );
}

/// quét mã sản phẩm rồi chuyển số lượng nhập tay lên tầng kệ đã chọn.
Future<void> _moveStockToShelf(
  BuildContext context,
  StaffController controller,
  StaffShelf shelf,
  int tier,
) async {
  final product = await _showBarcodeScanner(context, controller);
  if (product == null || !context.mounted) return;
  final quantity = await _askQuantity(
    context,
    title: 'Xếp hàng lên kệ ${shelf.code} · tầng $tier',
    product: product,
  );
  if (quantity == null || !context.mounted) return;
  try {
    controller.moveToShelf(
      shelfCode: shelf.code,
      tier: tier,
      product: product,
      quantity: quantity,
    );
    showSmartMartNotice(
      context,
      message: 'Đã chuyển $quantity ${product.name} lên kệ ${shelf.code}',
      icon: Icons.shelves,
    );
  } on StateError catch (error) {
    showSmartMartNotice(
      context,
      message: error.message,
      icon: Icons.error_outline_rounded,
    );
  }
}

/// mở cảnh báo chi tiết cho sản phẩm sắp hết ở tầng được chọn.
void _showLowStockDetails(
  BuildContext context,
  StaffShelf shelf,
  int tier,
  CartLine line,
) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(
        Icons.warning_amber_rounded,
        color: Color(0xFFD83D4D),
      ),
      title: Text('Sắp hết hàng · tầng $tier'),
      content: Text(
        '${line.product.name} (${line.product.packageSize ?? 'chưa rõ quy cách'}) '
        'còn ${line.quantity} sản phẩm trên kệ ${shelf.code}.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đã hiểu'),
        ),
      ],
    ),
  );
}

/// quét sản phẩm và thêm một đơn vị vào hóa đơn nháp.
Future<void> _scanSaleProduct(
  BuildContext context,
  StaffController controller,
) async {
  final product = await _showBarcodeScanner(context, controller);
  if (product == null || !context.mounted) return;
  try {
    controller.addSaleByBarcode(product.barcode ?? product.id);
    showSmartMartNotice(
      context,
      message: 'Đã thêm ${product.name} vào hóa đơn',
      icon: Icons.receipt_long_outlined,
    );
  } on StateError catch (error) {
    showSmartMartNotice(
      context,
      message: error.message,
      icon: Icons.error_outline_rounded,
    );
  }
}

/// tăng số lượng một dòng hóa đơn nếu lượng hàng trên kệ cho phép.
Future<void> _incrementSaleLine(
  BuildContext context,
  StaffController controller,
  CartLine line,
) async {
  try {
    controller.setSaleQuantity(line.product, line.quantity + 1);
  } on StateError catch (error) {
    showSmartMartNotice(
      context,
      message: error.message,
      icon: Icons.error_outline_rounded,
    );
  }
}

/// hoàn tất việc bán hàng rồi mở bản xem trước hóa đơn.
Future<void> _completeAndPreview(
  BuildContext context,
  StaffController controller,
) async {
  late final StaffSale sale;
  try {
    sale = controller.completeSale();
  } on StateError catch (error) {
    showSmartMartNotice(
      context,
      message: error.message,
      icon: Icons.error_outline_rounded,
    );
    return;
  }
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) => _InvoiceDialog(sale: sale),
  );
}

class _InvoiceDialog extends StatelessWidget {
  const _InvoiceDialog({required this.sale});

  final StaffSale sale;

  /// dựng bản xem trước hóa đơn với mã đơn, mặt hàng và tổng tiền.
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const ValueKey('staff-invoice-dialog'),
      icon: const Icon(Icons.receipt_long_rounded, color: AppColors.blue700),
      title: const Text('Hóa đơn bán hàng'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                sale.invoiceNumber,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 10),
              ),
              const Divider(height: 20),
              ...sale.lines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${line.product.name} × ${line.quantity}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                      Text(
                        formatVnd(line.total),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 18),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tổng cộng',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    formatVnd(sale.total),
                    style: const TextStyle(
                      color: AppColors.blue800,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Bản demo giao diện: máy in chưa được kết nối. Backend có thể thay bước này bằng dịch vụ in hóa đơn.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 9),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          key: const ValueKey('staff-invoice-print-preview'),
          onPressed: () => showSmartMartNotice(
            context,
            message: 'Bản xem trước đã sẵn sàng; chưa kết nối máy in.',
            icon: Icons.print_outlined,
          ),
          icon: const Icon(Icons.print_outlined),
          label: const Text('In hóa đơn'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hoàn tất'),
        ),
      ],
    );
  }
}

/// hiển thị mã định danh của kệ để nhân viên đối chiếu.
void _showShelfCode(BuildContext context, StaffShelf shelf) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Mã kệ ${shelf.code}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.qr_code_2_rounded, size: 128, color: AppColors.ink),
          Text(
            'SH-${shelf.code}-2024-001',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mã QR minh họa cho bản frontend.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );
}
