import 'package:flutter/material.dart';

import '../features/suppliers/screens/supplier_list_screen.dart';
import '../models/employee_management_models.dart';
import '../services/employee_management_service.dart';
import '../state/staff_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'goods_receipt_screens.dart';
import 'kho_addproduct.dart';
import 'restock_screens.dart';
import 'staff_screens.dart';

String formatCurrency(int amount) {
  final raw = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    if (i > 0 && (raw.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(raw[i]);
  }
  return '${buffer.toString()}đ';
}

// =============================================================================
// 1. TRANG CHỦ ADMIN (THIẾT KẾ THEO CHỦ ĐỀ HOMESCREEN + DASHBOARD CỬA HÀNG)
// =============================================================================

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({
    required this.userName,
    required this.userEmail,
    required this.staffController,
    required this.onOpenMenu,
    required this.onSelectBottomTab,
    required this.onLogout,
    super.key,
  });

  final String userName;
  final String userEmail;
  final StaffController staffController;
  final VoidCallback onOpenMenu;
  final ValueChanged<int> onSelectBottomTab;
  final VoidCallback onLogout;

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final EmployeeManagementService _service = EmployeeManagementService();
  final TextEditingController _searchController = TextEditingController();
  final PageController _bannerController = PageController();

  List<StoreRevenueSummary> _storeRevenues = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _period = 'MONTH'; // 'TODAY' | 'WEEK' | 'MONTH'
  int _bannerIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final list = await _service.getStoreRevenueSummaries();
      if (!mounted) return;
      setState(() {
        _storeRevenues = list;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  int _revenueForPeriod(StoreRevenueSummary s) {
    switch (_period) {
      case 'TODAY':
        return s.todayRevenue;
      case 'WEEK':
        return s.weekRevenue;
      default:
        return s.monthRevenue;
    }
  }

  int _ordersForPeriod(StoreRevenueSummary s) {
    switch (_period) {
      case 'TODAY':
        return s.todayOrders;
      case 'WEEK':
        return s.todayOrders * 6;
      default:
        return s.monthOrders;
    }
  }

  String get _periodLabel {
    switch (_period) {
      case 'TODAY':
        return 'Hôm nay';
      case 'WEEK':
        return '7 ngày qua';
      default:
        return 'Tháng này';
    }
  }

  void _openModuleScreen(Widget screen) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen))
        .then((_) => _loadDashboardData());
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final filteredStores = _storeRevenues.where((s) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      return s.storeName.toLowerCase().contains(q) ||
          s.address.toLowerCase().contains(q) ||
          s.managerName.toLowerCase().contains(q);
    }).toList();

    final totalRevenue =
        filteredStores.fold<int>(0, (sum, s) => sum + _revenueForPeriod(s));
    final totalOrders =
        filteredStores.fold<int>(0, (sum, s) => sum + _ordersForPeriod(s));
    final totalStaff =
        filteredStores.fold<int>(0, (sum, s) => sum + s.staffCount);
    final totalWorking =
        filteredStores.fold<int>(0, (sum, s) => sum + s.workingTodayCount);
    final totalLowStock =
        filteredStores.fold<int>(0, (sum, s) => sum + s.lowStockCount);

    return RefreshIndicator(
      color: AppColors.blue700,
      onRefresh: _loadDashboardData,
      child: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _CollapsingAdminHomeHeader(
              userName: widget.userName,
              storeCount: _storeRevenues.length,
              totalRevenue: totalRevenue,
              totalOrders: totalOrders,
              totalWorking: totalWorking,
              totalStaff: totalStaff,
              periodLabel: _periodLabel,
              onOpenMenu: widget.onOpenMenu,
              onRefreshTap: _loadDashboardData,
              onOpenFunctions: () => widget.onSelectBottomTab(1),
              searchController: _searchController,
              onSearchChanged: (v) => setState(() => _searchQuery = v),
              searchQuery: _searchQuery.trim(),
              topInset: topInset,
              bannerController: _bannerController,
              bannerIndex: _bannerIndex,
              onBannerChanged: (idx) => setState(() => _bannerIndex = idx),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
              decoration: const BoxDecoration(color: AppColors.canvas),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 5 CHỨC NĂNG TRọng TÂM (QUICK LAUNCH) ─────────────────
                  SectionHeading(
                    title: '5 Phân hệ Quản trị Hệ thống',
                    action: 'Tất cả chức năng',
                    onAction: () => widget.onSelectBottomTab(1),
                  ),
                  _AdminQuickModulesRow(
                    onOpenWarehouse: () => _openModuleScreen(
                      AdminWarehouseManagementScreen(
                        userName: widget.userName,
                        staffController: widget.staffController,
                      ),
                    ),
                    onOpenStore: () => _openModuleScreen(
                      AdminStoreManagementHubScreen(
                        userName: widget.userName,
                        staffController: widget.staffController,
                      ),
                    ),
                    onOpenSupplier: () => _openModuleScreen(
                      const SupplierListScreen(userRole: 'ADMIN'),
                    ),
                    onOpenEmployee: () => _openModuleScreen(
                      const AdminEmployeeManagementHubScreen(),
                    ),
                    onOpenStatistics: () => _openModuleScreen(
                      const AdminStatisticsScreen(),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── BỘ LỌC KỲ DASHBOARD CỬA HÀNG ─────────────────────────
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Dashboard Quản lý Cửa hàng',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      _PeriodFilterChip(
                        label: 'Hôm nay',
                        selected: _period == 'TODAY',
                        onTap: () => setState(() => _period = 'TODAY'),
                      ),
                      const SizedBox(width: 6),
                      _PeriodFilterChip(
                        label: 'Tuần',
                        selected: _period == 'WEEK',
                        onTap: () => setState(() => _period = 'WEEK'),
                      ),
                      const SizedBox(width: 6),
                      _PeriodFilterChip(
                        label: 'Tháng',
                        selected: _period == 'MONTH',
                        onTap: () => setState(() => _period = 'MONTH'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── 4 THẺ CHỈ SỐ KPI HỆ THỐNG CỬA HÀNG ───────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _DashboardMetricTile(
                          icon: Icons.payments_rounded,
                          label: 'Doanh thu ($_periodLabel)',
                          value: formatCurrency(totalRevenue),
                          subLabel: '+12.8% so với kỳ trước',
                          tint: const Color(0xFFEFF6FF),
                          iconColor: AppColors.blue700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DashboardMetricTile(
                          icon: Icons.receipt_long_rounded,
                          label: 'Tổng đơn bán ra',
                          value: '$totalOrders đơn',
                          subLabel: '${filteredStores.length} cơ sở hoạt động',
                          tint: const Color(0xFFECFDF5),
                          iconColor: const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _DashboardMetricTile(
                          icon: Icons.groups_rounded,
                          label: 'Nhân sự đi làm hôm nay',
                          value: '$totalWorking / $totalStaff NV',
                          subLabel: 'Bấm để chấm công NV',
                          tint: const Color(0xFFFFF7ED),
                          iconColor: const Color(0xFFEA580C),
                          onTap: () => _openModuleScreen(
                            const AdminEmployeeManagementHubScreen(
                              initialSubTab: 0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DashboardMetricTile(
                          icon: Icons.warning_amber_rounded,
                          label: 'Cảnh báo tồn kệ thấp',
                          value: '$totalLowStock mặt hàng',
                          subLabel: 'Xem thống kê tồn kho',
                          tint: const Color(0xFFFEF2F2),
                          iconColor: const Color(0xFFDC2626),
                          onTap: () => _openModuleScreen(
                            const AdminStatisticsScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ── DANH SÁCH DASHBOARD CHI TIẾT TỪNG CỬA HÀNG ───────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Thông tin vận hành từng Cửa hàng (${filteredStores.length})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => widget.onSelectBottomTab(2),
                        icon: const Icon(Icons.storefront_rounded, size: 16),
                        label: const Text('Mở tab Cửa hàng'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (filteredStores.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Center(
                        child: Text(
                          'Không tìm thấy cửa hàng phù hợp với từ khóa.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ),
                    )
                  else
                    ...filteredStores.map(
                      (store) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _StoreDashboardCard(
                          summary: store,
                          periodRevenue: _revenueForPeriod(store),
                          periodOrders: _ordersForPeriod(store),
                          periodLabel: _periodLabel,
                          onOpenDetail: () =>
                              _showStoreDetailModal(context, store),
                          onOpenWorkspace: () => _openModuleScreen(
                            StoreStaffWorkspace(
                              controller: widget.staffController,
                              staffName: widget.userName,
                              userRole: 'ADMIN',
                              onExit: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStoreDetailModal(BuildContext context, StoreRevenueSummary store) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.blue50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: AppColors.blue700,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.storeName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          store.address,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),
              _InfoRowItem(
                label: 'Quản lý cửa hàng',
                value: store.managerName,
                icon: Icons.badge_outlined,
              ),
              _InfoRowItem(
                label: 'Số điện thoại hotline',
                value: store.phone,
                icon: Icons.phone_outlined,
              ),
              _InfoRowItem(
                label: 'Nhân sự đi làm hôm nay',
                value: '${store.workingTodayCount}/${store.staffCount} nhân viên',
                icon: Icons.groups_outlined,
              ),
              _InfoRowItem(
                label: 'Doanh thu hôm nay',
                value: formatCurrency(store.todayRevenue),
                icon: Icons.today_outlined,
              ),
              _InfoRowItem(
                label: 'Doanh thu tháng này',
                value: formatCurrency(store.monthRevenue),
                icon: Icons.calendar_month_outlined,
              ),
              _InfoRowItem(
                label: 'Chỉ tiêu KPI tháng',
                value:
                    '${formatCurrency(store.monthlyTarget)} (${(store.targetProgress * 100).toStringAsFixed(1)}%)',
                icon: Icons.flag_outlined,
              ),
              _InfoRowItem(
                label: 'Tổng tồn kệ hiện tại',
                value:
                    '${store.stockQuantity} SP (${store.lowStockCount} mã sắp hết)',
                icon: Icons.inventory_2_outlined,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _openModuleScreen(
                          const RestockRequestsScreen(userRole: 'ADMIN'),
                        );
                      },
                      icon: const Icon(Icons.assignment_outlined, size: 18),
                      label: const Text('Phiếu yêu cầu hàng'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _openModuleScreen(
                          StoreStaffWorkspace(
                            controller: widget.staffController,
                            staffName: widget.userName,
                            userRole: 'ADMIN',
                            onExit: () => Navigator.of(context).pop(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.point_of_sale_rounded, size: 18),
                      label: const Text('Vào POS Cửa hàng'),
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

class _CollapsingAdminHomeHeader extends SliverPersistentHeaderDelegate {
  const _CollapsingAdminHomeHeader({
    required this.userName,
    required this.storeCount,
    required this.totalRevenue,
    required this.totalOrders,
    required this.totalWorking,
    required this.totalStaff,
    required this.periodLabel,
    required this.onOpenMenu,
    required this.onRefreshTap,
    required this.onOpenFunctions,
    required this.searchController,
    required this.onSearchChanged,
    required this.searchQuery,
    required this.topInset,
    required this.bannerController,
    required this.bannerIndex,
    required this.onBannerChanged,
  });

  final String userName;
  final int storeCount;
  final int totalRevenue;
  final int totalOrders;
  final int totalWorking;
  final int totalStaff;
  final String periodLabel;
  final VoidCallback onOpenMenu;
  final VoidCallback onRefreshTap;
  final VoidCallback onOpenFunctions;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final String searchQuery;
  final double topInset;
  final PageController bannerController;
  final int bannerIndex;
  final ValueChanged<int> onBannerChanged;

  @override
  double get minExtent => topInset + 106;

  @override
  double get maxExtent => topInset + 324;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final bottomRadius = Radius.circular(28 - (10 * progress));
    final searchTop = topInset + 80 - 52 * progress;
    final bannerOpacity = (1 - progress * 1.35).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.blue900, AppColors.blue800, AppColors.blue700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: bottomRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue900.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Hàng trên cùng: Menu + Tiêu đề Hệ thống Quản trị + Làm mới
          Positioned(
            top: topInset + 12,
            left: 16,
            right: 16,
            child: Opacity(
              opacity: (1 - progress * 1.6).clamp(0.0, 1.0),
              child: Row(
                children: [
                  _AdminRoundHeaderIcon(
                    icon: Icons.menu_rounded,
                    onTap: onOpenMenu,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.admin_panel_settings_rounded,
                            color: Color(0xFFFFD58A),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Hệ thống Quản trị SSM4 • ${userName.isNotEmpty ? userName : "Admin"}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _AdminRoundHeaderIcon(
                    icon: Icons.sync_rounded,
                    onTap: onRefreshTap,
                  ),
                  const SizedBox(width: 8),
                  _AdminRoundHeaderIcon(
                    icon: Icons.grid_view_rounded,
                    onTap: onOpenFunctions,
                  ),
                ],
              ),
            ),
          ),

          // Carousel Banner Quản trị Hệ thống (thay thế banner khuyến mãi khách hàng)
          Positioned(
            top: topInset + 148,
            left: 0,
            right: 0,
            height: 158,
            child: IgnorePointer(
              ignoring: bannerOpacity < 0.15,
              child: Opacity(
                opacity: bannerOpacity,
                child: Column(
                  children: [
                    Expanded(
                      child: PageView(
                        controller: bannerController,
                        onPageChanged: onBannerChanged,
                        children: [
                          _AdminHeroBannerCard(
                            badge: 'TỔNG DOANH THU ($periodLabel)',
                            title: formatCurrency(totalRevenue),
                            subtitle:
                                '$totalOrders đơn hoàn tất tại $storeCount cơ sở cửa hàng đang hoạt động',
                            icon: Icons.query_stats_rounded,
                            accentColor: const Color(0xFF00B4D8),
                          ),
                          _AdminHeroBannerCard(
                            badge: 'NHÂN SỰ & CHẤM CÔNG HÔM NAY',
                            title: '$totalWorking / $totalStaff Nhân viên',
                            subtitle:
                                'Đang làm việc tại các cơ sở Cửa hàng & Kho trung tâm SSM4',
                            icon: Icons.fact_check_rounded,
                            accentColor: const Color(0xFF10B981),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        2,
                        (idx) => AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: idx == bannerIndex ? 18 : 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: idx == bannerIndex
                                ? Colors.white
                                : Colors.white54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Thanh tìm kiếm cửa hàng ghim khi cuộn (giống HomeScreen)
          Positioned(
            top: searchTop,
            left: 16,
            right: 16,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blue900.withValues(alpha: 0.14),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppColors.blue700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText:
                            'Tìm cửa hàng, địa chỉ hoặc quản lý phụ trách...',
                        hintStyle: TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  if (searchQuery.isNotEmpty)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.muted,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CollapsingAdminHomeHeader oldDelegate) => true;
}

class _AdminRoundHeaderIcon extends StatelessWidget {
  const _AdminRoundHeaderIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _AdminHeroBannerCard extends StatelessWidget {
  const _AdminHeroBannerCard({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });

  final String badge;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Color(0xFFFFE599),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFDCEBFA),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminQuickModulesRow extends StatelessWidget {
  const _AdminQuickModulesRow({
    required this.onOpenWarehouse,
    required this.onOpenStore,
    required this.onOpenSupplier,
    required this.onOpenEmployee,
    required this.onOpenStatistics,
  });

  final VoidCallback onOpenWarehouse;
  final VoidCallback onOpenStore;
  final VoidCallback onOpenSupplier;
  final VoidCallback onOpenEmployee;
  final VoidCallback onOpenStatistics;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, Color, Color, VoidCallback)>[
      (
        Icons.warehouse_rounded,
        'QL Kho',
        const Color(0xFFECFDF5),
        const Color(0xFF059669),
        onOpenWarehouse,
      ),
      (
        Icons.storefront_rounded,
        'QL Cửa hàng',
        const Color(0xFFFFF7ED),
        const Color(0xFFEA580C),
        onOpenStore,
      ),
      (
        Icons.business_rounded,
        'Nhà cung cấp',
        const Color(0xFFEFF6FF),
        AppColors.blue700,
        onOpenSupplier,
      ),
      (
        Icons.groups_rounded,
        'QL Nhân viên',
        const Color(0xFFF5F3FF),
        const Color(0xFF7C3AED),
        onOpenEmployee,
      ),
      (
        Icons.bar_chart_rounded,
        'QL Thống kê',
        const Color(0xFFFEF2F2),
        const Color(0xFFDC2626),
        onOpenStatistics,
      ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: item.$5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: item.$3,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: item.$4.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(item.$1, color: item.$4, size: 26),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.$2,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PeriodFilterChip extends StatelessWidget {
  const _PeriodFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue700 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.blue700 : AppColors.line,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _DashboardMetricTile extends StatelessWidget {
  const _DashboardMetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.subLabel,
    required this.tint,
    required this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String subLabel;
  final Color tint;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 19),
                  ),
                  const Spacer(),
                  if (onTap != null)
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: AppColors.muted,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: iconColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreDashboardCard extends StatelessWidget {
  const _StoreDashboardCard({
    required this.summary,
    required this.periodRevenue,
    required this.periodOrders,
    required this.periodLabel,
    required this.onOpenDetail,
    required this.onOpenWorkspace,
  });

  final StoreRevenueSummary summary;
  final int periodRevenue;
  final int periodOrders;
  final String periodLabel;
  final VoidCallback onOpenDetail;
  final VoidCallback onOpenWorkspace;

  @override
  Widget build(BuildContext context) {
    final progressPct = (summary.targetProgress * 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue900.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.blue50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.blue700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.storeName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      summary.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${summary.growthPercent.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Doanh thu ($periodLabel)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatCurrency(periodRevenue),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.blue900,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 32, color: AppColors.line),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đơn hàng & Tồn kệ',
                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$periodOrders đơn • ${summary.stockQuantity} SP',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.person_pin_rounded,
                size: 15,
                color: AppColors.blue700,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'QL: ${summary.managerName} • Đi làm: ${summary.workingTodayCount}/${summary.staffCount} NV',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                'KPI tháng: $progressPct%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: summary.targetProgress,
              minHeight: 6,
              backgroundColor: AppColors.blue50,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.blue700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenDetail,
                  icon: const Icon(Icons.analytics_outlined, size: 16),
                  label: const Text('Thông tin cửa hàng'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onOpenWorkspace,
                  icon: const Icon(Icons.store_mall_directory_rounded, size: 16),
                  label: const Text('Quản lý cửa hàng'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRowItem extends StatelessWidget {
  const _InfoRowItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.blue700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 2. TAB "CHỨC NĂNG" TRÊN THANH ĐIỀU HƯỚNG (5 CHỨC NĂNG LỚN CỦA ADMIN)
//    1. Quản lý Kho
//    2. Quản lý Cửa hàng
//    3. Quản lý Nhà cung cấp
//    4. Quản lý Nhân viên
//    5. Quản lý Thống kê
// =============================================================================

class AdminFunctionsMenuScreen extends StatelessWidget {
  const AdminFunctionsMenuScreen({
    required this.userName,
    required this.staffController,
    required this.onSelectBottomTab,
    super.key,
  });

  final String userName;
  final StaffController staffController;
  final ValueChanged<int> onSelectBottomTab;

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        // Banner giới thiệu 5 phân hệ
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
                color: AppColors.blue900.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Color(0x33FFFFFF),
                child: Icon(
                  Icons.apps_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TRUNG TÂM ĐIỀU HÀNH ADMIN',
                      style: TextStyle(
                        color: Color(0xFFFFD58A),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '5 Phân hệ Quản lý Trọng tâm',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Chọn chức năng để điều phối kho, cửa hàng, nhà cung cấp, nhân sự và thống kê toàn chuỗi.',
                      style: TextStyle(
                        color: Color(0xFFDCEBFA),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 1. QUẢN LÝ KHO
        _BigFeatureModuleCard(
          indexNumber: '01',
          icon: Icons.warehouse_rounded,
          title: 'Quản lý Kho hàng',
          subtitle:
              'Phiếu nhập hàng từ NCC, lập phiếu nhập mới, duyệt phiếu yêu cầu từ cửa hàng, thêm sản phẩm & tồn kho.',
          tags: const [
            'Phiếu nhập NCC',
            'Duyệt xuất kho',
            'Tồn kho dự trữ',
          ],
          accentColor: const Color(0xFF059669),
          tintColor: const Color(0xFFECFDF5),
          onTap: () => _open(
            context,
            AdminWarehouseManagementScreen(
              userName: userName,
              staffController: staffController,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // 2. QUẢN LÝ CỬA HÀNG
        _BigFeatureModuleCard(
          indexNumber: '02',
          icon: Icons.storefront_rounded,
          title: 'Quản lý Cửa hàng',
          subtitle:
              'Vận hành cửa hàng POS, kiểm soát tồn kệ trưng bày, lập và theo dõi phiếu yêu cầu tiếp hàng từ kho.',
          tags: const [
            'Bán hàng POS',
            'Tồn kệ cửa hàng',
            'Phiếu yêu cầu hàng',
          ],
          accentColor: const Color(0xFFEA580C),
          tintColor: const Color(0xFFFFF7ED),
          onTap: () => _open(
            context,
            AdminStoreManagementHubScreen(
              userName: userName,
              staffController: staffController,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // 3. QUẢN LÝ NHÀ CUNG CẤP
        _BigFeatureModuleCard(
          indexNumber: '03',
          icon: Icons.business_rounded,
          title: 'Quản lý Nhà cung cấp',
          subtitle:
              'Danh bạ đối tác cung ứng hàng hóa, thêm mới, chỉnh sửa thông tin liên hệ và kích hoạt/ngừng hợp tác.',
          tags: const [
            'Danh sách NCC',
            'Thêm / Sửa NCC',
            'Trạng thái hợp tác',
          ],
          accentColor: AppColors.blue700,
          tintColor: const Color(0xFFEFF6FF),
          onTap: () => _open(
            context,
            const SupplierListScreen(userRole: 'ADMIN'),
          ),
        ),
        const SizedBox(height: 14),

        // 4. QUẢN LÝ NHÂN VIÊN
        _BigFeatureModuleCard(
          indexNumber: '04',
          icon: Icons.groups_rounded,
          title: 'Quản lý Nhân viên',
          subtitle:
              'Chấm công nhân viên theo từng cơ sở (Đang làm / Đang nghỉ), quản lý & sửa tài khoản nhân viên, tạo tài khoản mới.',
          tags: const [
            'Chấm công theo cơ sở',
            'Sửa tài khoản NV',
            'Tạo tài khoản NV',
          ],
          accentColor: const Color(0xFF7C3AED),
          tintColor: const Color(0xFFF5F3FF),
          onTap: () => _open(
            context,
            const AdminEmployeeManagementHubScreen(),
          ),
        ),
        const SizedBox(height: 14),

        // 5. QUẢN LÝ THỐNG KÊ
        _BigFeatureModuleCard(
          indexNumber: '05',
          icon: Icons.insert_chart_outlined_rounded,
          title: 'Quản lý Thống kê',
          subtitle:
              'Theo dõi lượng hàng tồn kệ/tồn kho, sức chứa, lượng nhập vào và lượng bán ra/xuất kho của từng cơ sở Kho & Cửa hàng.',
          tags: const [
            'Lượng hàng cơ sở',
            'Lượng bán & Xuất kho',
            'Báo cáo doanh thu',
          ],
          accentColor: const Color(0xFFDC2626),
          tintColor: const Color(0xFFFEF2F2),
          onTap: () => _open(
            context,
            const AdminStatisticsScreen(),
          ),
        ),
      ],
    );
  }
}

class _BigFeatureModuleCard extends StatelessWidget {
  const _BigFeatureModuleCard({
    required this.indexNumber,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tags,
    required this.accentColor,
    required this.tintColor,
    required this.onTap,
  });

  final String indexNumber;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> tags;
  final Color accentColor;
  final Color tintColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: accentColor.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: tintColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: accentColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tintColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'PHÂN HỆ $indexNumber',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: tintColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: accentColor,
                      size: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: tags
                    .map(
                      (t) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Text(
                          t,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 2.1. PHÂN HỆ 01: QUẢN LÝ KHO HÀNG (GIỮ NGUYÊN CHỨC NĂNG CŨ, NÂNG CẤP UI)
// =============================================================================

class AdminWarehouseManagementScreen extends StatelessWidget {
  const AdminWarehouseManagementScreen({
    required this.userName,
    required this.staffController,
    super.key,
  });

  final String userName;
  final StaffController staffController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Quản lý Kho hàng'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF065F46), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Color(0x33FFFFFF),
                  child: Icon(
                    Icons.warehouse_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ĐIỀU PHỐI KHO TRUNG TÂM',
                        style: TextStyle(
                          color: Color(0xFFA7F3D0),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Hệ thống Quản lý Kho & Nhập xuất',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Nhập hàng từ nhà cung cấp, duyệt yêu cầu từ cửa hàng và quản lý danh mục sản phẩm.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SubFeatureActionTile(
            icon: Icons.inventory_2_rounded,
            title: 'Phiếu nhập hàng từ Nhà cung cấp',
            subtitle:
                'Xem toàn bộ phiếu nhập kho, lọc theo trạng thái nháp / hoàn tất / đã hủy',
            tint: const Color(0xFFECFDF5),
            iconColor: const Color(0xFF059669),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const GoodsReceiptsScreen(userRole: 'ADMIN'),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _SubFeatureActionTile(
            icon: Icons.add_circle_outline_rounded,
            title: 'Tạo phiếu nhập kho mới',
            subtitle:
                'Lập phiếu nhập hàng mới từ nhà cung cấp vào kho trung tâm được chọn',
            tint: const Color(0xFFFFFBEB),
            iconColor: const Color(0xFFB45309),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    const CreateGoodsReceiptScreen(userRole: 'ADMIN'),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _SubFeatureActionTile(
            icon: Icons.assignment_turned_in_rounded,
            title: 'Phiếu yêu cầu hàng từ Cửa hàng',
            subtitle:
                'Duyệt số lượng, từ chối hoặc xác nhận xuất kho giao hàng cho cửa hàng',
            tint: AppColors.blue50,
            iconColor: AppColors.blue700,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    const WarehouseRestockRequestsScreen(userRole: 'ADMIN'),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _SubFeatureActionTile(
            icon: Icons.add_box_rounded,
            title: 'Thêm sản phẩm mới vào Kho',
            subtitle:
                'Tạo mặt hàng mới, gán mã vạch, giá nhập/bán và khởi tạo tồn kho ban đầu',
            tint: const Color(0xFFF5F3FF),
            iconColor: const Color(0xFF7C3AED),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    KhoAddProductScreen(controller: staffController),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _SubFeatureActionTile(
            icon: Icons.dashboard_customize_rounded,
            title: 'Giao diện Nghiệp vụ Kho đầy đủ',
            subtitle:
                'Mở toàn bộ không gian làm việc của nhân viên kho (Tồn kho, Nhập kho, Chuyển kệ)',
            tint: const Color(0xFFF0FDF4),
            iconColor: const Color(0xFF15803D),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => WarehouseStaffWorkspace(
                  controller: staffController,
                  staffName: userName,
                  userRole: 'ADMIN',
                  onExit: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 2.2. PHÂN HỆ 02 & TAB "CỬA HÀNG": QUẢN LÝ CỬA HÀNG (GIỮ NGUYÊN LOGIC CŨ + UI ĐẸP)
// =============================================================================

class AdminStoreManagementHubScreen extends StatelessWidget {
  const AdminStoreManagementHubScreen({
    required this.userName,
    required this.staffController,
    super.key,
  });

  final String userName;
  final StaffController staffController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Quản lý Cửa hàng'),
      ),
      body: AdminStoresTabScreen(
        userName: userName,
        staffController: staffController,
      ),
    );
  }
}

class AdminStoresTabScreen extends StatefulWidget {
  const AdminStoresTabScreen({
    required this.userName,
    required this.staffController,
    super.key,
  });

  final String userName;
  final StaffController staffController;

  @override
  State<AdminStoresTabScreen> createState() => _AdminStoresTabScreenState();
}

class _AdminStoresTabScreenState extends State<AdminStoresTabScreen> {
  final EmployeeManagementService _service = EmployeeManagementService();
  List<StoreRevenueSummary> _stores = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _service.getStoreRevenueSummaries();
      if (!mounted) return;
      setState(() {
        _stores = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9A3412), Color(0xFFEA580C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Color(0x33FFFFFF),
                  child: Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HỆ THỐNG CỬA HÀNG BÁN LẺ',
                        style: TextStyle(
                          color: Color(0xFFFED7AA),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Quản lý Cửa hàng & Nghiệp vụ POS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Bán hàng tại quầy, kiểm tra tồn kệ và lập phiếu yêu cầu xuất hàng từ kho.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chức năng Nghiệp vụ Cửa hàng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          _SubFeatureActionTile(
            icon: Icons.point_of_sale_rounded,
            title: 'Giao diện Cửa hàng & Bán hàng POS đầy đủ',
            subtitle:
                'Toàn bộ chức năng cửa hàng: Bán hàng tại quầy, Tồn kệ trưng bày, Chuyển hàng lên kệ',
            tint: const Color(0xFFFFF7ED),
            iconColor: const Color(0xFFEA580C),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => StoreStaffWorkspace(
                  controller: widget.staffController,
                  staffName: widget.userName,
                  userRole: 'ADMIN',
                  onExit: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _SubFeatureActionTile(
            icon: Icons.assignment_outlined,
            title: 'Danh sách Phiếu yêu cầu hàng của Cửa hàng',
            subtitle:
                'Xem tiến độ các phiếu yêu cầu tiếp hàng từ kho và xác nhận nhận hàng vào kệ',
            tint: AppColors.blue50,
            iconColor: AppColors.blue700,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const RestockRequestsScreen(userRole: 'ADMIN'),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _SubFeatureActionTile(
            icon: Icons.add_shopping_cart_rounded,
            title: 'Tạo Phiếu yêu cầu hàng mới',
            subtitle:
                'Lập phiếu yêu cầu xuất hàng từ kho trung tâm về cửa hàng được chọn',
            tint: const Color(0xFFECFDF5),
            iconColor: const Color(0xFF059669),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    const CreateRestockRequestScreen(userRole: 'ADMIN'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Danh sách Cơ sở Cửa hàng (${_stores.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            ..._stores.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _StoreDashboardCard(
                  summary: s,
                  periodRevenue: s.monthRevenue,
                  periodOrders: s.monthOrders,
                  periodLabel: 'Tháng này',
                  onOpenDetail: () {},
                  onOpenWorkspace: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => StoreStaffWorkspace(
                        controller: widget.staffController,
                        staffName: widget.userName,
                        userRole: 'ADMIN',
                        onExit: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SubFeatureActionTile extends StatelessWidget {
  const _SubFeatureActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 3. PHÂN HỆ 04: QUẢN LÝ NHÂN VIÊN (GỒM 3 CHỨC NĂNG CON)
//    1. Chấm công cho nhân viên (theo từng cơ sở, đánh dấu Đang làm / Đang nghỉ)
//    2. Quản lý tài khoản nhân viên (xem, sửa Tên, Email, Chức vụ, Nơi làm việc)
//    3. Tạo tài khoản cho nhân viên (giao diện UI hoàn chỉnh)
// =============================================================================

class AdminEmployeeManagementHubScreen extends StatefulWidget {
  const AdminEmployeeManagementHubScreen({
    this.initialSubTab = 0,
    super.key,
  });

  final int initialSubTab;

  @override
  State<AdminEmployeeManagementHubScreen> createState() =>
      _AdminEmployeeManagementHubScreenState();
}

class _AdminEmployeeManagementHubScreenState
    extends State<AdminEmployeeManagementHubScreen> {
  late int _subTab;

  @override
  void initState() {
    super.initState();
    _subTab = widget.initialSubTab.clamp(0, 2);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const AdminAttendanceScreen(embedded: true),
      const AdminStaffProfileManagementScreen(embedded: true),
      const AdminCreateEmployeeScreen(embedded: true),
    ];

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Quản lý Nhân viên'),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: _EmployeeSubTabButton(
                    icon: Icons.fact_check_rounded,
                    label: 'Chấm công NV',
                    selected: _subTab == 0,
                    onTap: () => setState(() => _subTab = 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _EmployeeSubTabButton(
                    icon: Icons.manage_accounts_rounded,
                    label: 'QL Tài khoản NV',
                    selected: _subTab == 1,
                    onTap: () => setState(() => _subTab = 1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _EmployeeSubTabButton(
                    icon: Icons.person_add_alt_1_rounded,
                    label: 'Tạo TK NV',
                    selected: _subTab == 2,
                    onTap: () => setState(() => _subTab = 2),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: IndexedStack(
              index: _subTab,
              children: pages,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeSubTabButton extends StatelessWidget {
  const _EmployeeSubTabButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue700 : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? Colors.white : AppColors.blue900,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 3.1. CHỨC NĂNG CON 1: CHẤM CÔNG CHO NHÂN VIÊN THEO TỪNG CƠ SỞ
//      (Đánh dấu Đang làm / Đang nghỉ trực tiếp trên từng nhân viên + Quản lý ngày công)
// =============================================================================

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({
    this.embedded = false,
    super.key,
  });

  final bool embedded;

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  final EmployeeManagementService _service = EmployeeManagementService();
  final TextEditingController _searchController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  List<EmployeeRecord> _employees = [];
  List<BranchLocation> _stores = [];
  List<BranchLocation> _warehouses = [];
  Map<String, bool> _workingMap = {};
  Map<String, TimesheetPayrollRecord> _timesheetMap = {};

  bool _isLoading = true;
  String _selectedFacilityFilter = 'ALL';
  String _statusFilter = 'ALL'; // 'ALL' | 'WORKING' | 'OFF'
  String _searchQuery = '';

  String get _monthYear =>
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getEmployees(),
        _service.getStores(),
        _service.getWarehouses(),
        _service.getShifts(startDate: _selectedDate, endDate: _selectedDate),
        _service.getTimesheets(monthYear: _monthYear),
      ]);

      if (!mounted) return;
      final emps = results[0] as List<EmployeeRecord>;
      final stores = results[1] as List<BranchLocation>;
      final warehouses = results[2] as List<BranchLocation>;
      final shifts = results[3] as List<WorkShiftRecord>;
      final timesheets = results[4] as List<TimesheetPayrollRecord>;

      final wMap = <String, bool>{};
      for (final emp in emps) {
        final foundShift =
            shifts.where((s) => s.employeeId == emp.id).firstOrNull;
        wMap[emp.id] = foundShift != null ? foundShift.isWorking : emp.isActive;
      }

      final tsMap = <String, TimesheetPayrollRecord>{
        for (final t in timesheets) t.employeeId: t,
      };

      setState(() {
        _employees = emps;
        _stores = stores;
        _warehouses = warehouses;
        _workingMap = wMap;
        _timesheetMap = tsMap;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
      await _loadData();
    }
  }

  Future<void> _setWorkingStatus(EmployeeRecord emp, bool nextWorking) async {
    final prevWorking = _workingMap[emp.id] ?? emp.isActive;
    if (prevWorking == nextWorking) return;

    final currentSheet = _timesheetMap[emp.id];
    final currentDays = currentSheet?.workDays ?? emp.workDays;
    final nextDays = (currentDays + (nextWorking ? 1 : -1)).clamp(0, 31);

    setState(() {
      _workingMap[emp.id] = nextWorking;
      if (currentSheet != null) {
        _timesheetMap[emp.id] = currentSheet.copyWith(
          workDays: nextDays,
          totalHours: nextDays * 8.0,
        );
      }
    });

    final savedDays = await _service.markAttendanceStatus(
      employee: emp,
      workDate: _selectedDate,
      monthYear: _monthYear,
      isWorking: nextWorking,
      nextWorkDays: nextDays,
      currentTimesheet: currentSheet,
    );

    if (!mounted) return;
    if (currentSheet != null && savedDays != nextDays) {
      setState(() {
        _timesheetMap[emp.id] = currentSheet.copyWith(
          workDays: savedDays,
          totalHours: savedDays * 8.0,
        );
      });
    }

    showSmartMartNotice(
      context,
      message: nextWorking
          ? 'Đã đánh dấu ${emp.fullName}: ĐANG LÀM (${emp.facilityGroupName})'
          : 'Đã đánh dấu ${emp.fullName}: ĐANG NGHỈ (${emp.facilityGroupName})',
      icon: nextWorking
          ? Icons.check_circle_rounded
          : Icons.pause_circle_filled_rounded,
    );
  }

  Future<void> _showEditWorkDaysDialog(EmployeeRecord emp) async {
    final sheet = _timesheetMap[emp.id];
    int tempDays = sheet?.workDays ?? emp.workDays;

    final confirmed = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            'Quản lý ngày công • ${emp.fullName}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cơ sở: ${emp.facilityGroupName}\nKỳ chấm công: Tháng $_monthYear',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: () => setDialogState(
                      () => tempDays = (tempDays - 1).clamp(0, 31),
                    ),
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    '$tempDays / 26 ngày',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.blue900,
                    ),
                  ),
                  const SizedBox(width: 20),
                  IconButton.filledTonal(
                    onPressed: () => setDialogState(
                      () => tempDays = (tempDays + 1).clamp(0, 31),
                    ),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(tempDays),
              child: const Text('Lưu ngày công'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != null && mounted) {
      final updated = await _service.updateEmployeeWorkDays(
        employee: emp,
        monthYear: _monthYear,
        workDays: confirmed,
        currentTimesheet: sheet,
      );
      if (!mounted) return;
      setState(() {
        if (updated != null) {
          _timesheetMap[emp.id] = updated;
        }
      });
      showSmartMartNotice(
        context,
        message: 'Đã cập nhật $confirmed ngày công cho ${emp.fullName}.',
        icon: Icons.event_available_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final facilityNames = <String>{
      'ALL',
      for (final s in _stores) s.name,
      for (final w in _warehouses) w.name,
      for (final e in _employees) e.facilityGroupName,
    }.toList();

    final filtered = _employees.where((e) {
      if (_selectedFacilityFilter != 'ALL' &&
          e.facilityGroupName != _selectedFacilityFilter) {
        return false;
      }
      final working = _workingMap[e.id] ?? e.isActive;
      if (_statusFilter == 'WORKING' && !working) return false;
      if (_statusFilter == 'OFF' && working) return false;
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        return e.fullName.toLowerCase().contains(q) ||
            e.email.toLowerCase().contains(q) ||
            e.code.toLowerCase().contains(q) ||
            e.facilityGroupName.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    // Gom nhóm nhân viên theo từng cơ sở
    final Map<String, List<EmployeeRecord>> groupedByFacility = {};
    for (final emp in filtered) {
      groupedByFacility
          .putIfAbsent(emp.facilityGroupName, () => <EmployeeRecord>[])
          .add(emp);
    }

    final totalCount = filtered.length;
    final workingCount =
        filtered.where((e) => _workingMap[e.id] ?? e.isActive).length;
    final offCount = totalCount - workingCount;

    final body = RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
        children: [
          // Header chọn ngày & Thống kê Đi làm / Đang nghỉ
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.blue900, AppColors.blue700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: Color(0xFFFFD58A),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CHẤM CÔNG NHÂN VIÊN THEO CƠ SỞ',
                            style: TextStyle(
                              color: Color(0xFFFFD58A),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ngày ${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _pickDate,
                      icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                      label: const Text('Đổi ngày'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _AttendanceCountBadge(
                        label: 'Tổng nhân sự',
                        count: totalCount,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AttendanceCountBadge(
                        label: 'Đang làm',
                        count: workingCount,
                        color: const Color(0xFF6EE7B7),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AttendanceCountBadge(
                        label: 'Đang nghỉ',
                        count: offCount,
                        color: const Color(0xFFFCA5A5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Tìm kiếm nhân viên
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: 'Tìm tên nhân viên, mã NV hoặc tên cơ sở...',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.line),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Bộ lọc Cơ sở làm việc
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: facilityNames.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final f = facilityNames[index];
                final selected = _selectedFacilityFilter == f;
                return ChoiceChip(
                  label: Text(f == 'ALL' ? 'Tất cả cơ sở' : f),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _selectedFacilityFilter = f),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Bộ lọc Trạng thái Đang làm / Đang nghỉ
          Row(
            children: [
              _PeriodFilterChip(
                label: 'Tất cả ($totalCount)',
                selected: _statusFilter == 'ALL',
                onTap: () => setState(() => _statusFilter = 'ALL'),
              ),
              const SizedBox(width: 8),
              _PeriodFilterChip(
                label: 'Đang làm ($workingCount)',
                selected: _statusFilter == 'WORKING',
                onTap: () => setState(() => _statusFilter = 'WORKING'),
              ),
              const SizedBox(width: 8),
              _PeriodFilterChip(
                label: 'Đang nghỉ ($offCount)',
                selected: _statusFilter == 'OFF',
                onTap: () => setState(() => _statusFilter = 'OFF'),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (groupedByFacility.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.line),
              ),
              child: const Center(
                child: Text(
                  'Không có nhân viên nào trong cơ sở được chọn.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            )
          else
            ...groupedByFacility.entries.map((entry) {
              final facilityName = entry.key;
              final staffList = entry.value;
              final facWorking = staffList
                  .where((e) => _workingMap[e.id] ?? e.isActive)
                  .length;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề Cơ sở
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              facilityName.toLowerCase().contains('kho')
                                  ? Icons.warehouse_rounded
                                  : Icons.storefront_rounded,
                              color: AppColors.blue700,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                facilityName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
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
                                'Đi làm: $facWorking/${staffList.length}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.blue700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // Danh sách nhân viên trong cơ sở
                      ...staffList.map((emp) {
                        final isWorking = _workingMap[emp.id] ?? emp.isActive;
                        final workDays =
                            _timesheetMap[emp.id]?.workDays ?? emp.workDays;
                        return Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: isWorking
                                        ? const Color(0xFFECFDF5)
                                        : const Color(0xFFFEF2F2),
                                    child: Icon(
                                      isWorking
                                          ? Icons.person_pin_circle_rounded
                                          : Icons.person_off_rounded,
                                      color: isWorking
                                          ? const Color(0xFF059669)
                                          : const Color(0xFFDC2626),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                emp.fullName,
                                                style: const TextStyle(
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.ink,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isWorking
                                                    ? const Color(0xFFECFDF5)
                                                    : const Color(0xFFFEF2F2),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                isWorking
                                                    ? '● Đang làm'
                                                    : '○ Đang nghỉ',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                  color: isWorking
                                                      ? const Color(0xFF059669)
                                                      : const Color(0xFFDC2626),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${emp.code} • ${emp.roleLabel}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.muted,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        InkWell(
                                          onTap: () =>
                                              _showEditWorkDaysDialog(emp),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.event_note_rounded,
                                                size: 14,
                                                color: AppColors.blue700,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Công tháng $_monthYear: $workDays/26 ngày (Sửa)',
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.blue700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // 2 Nút đánh dấu Đang làm / Đang nghỉ trực tiếp
                              Row(
                                children: [
                                  Expanded(
                                    child: isWorking
                                        ? FilledButton.icon(
                                            style: FilledButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF059669,
                                              ),
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                            onPressed: () =>
                                                _setWorkingStatus(emp, true),
                                            icon: const Icon(
                                              Icons.check_circle_rounded,
                                              size: 16,
                                            ),
                                            label: const Text('Đang làm'),
                                          )
                                        : OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                            onPressed: () =>
                                                _setWorkingStatus(emp, true),
                                            icon: const Icon(
                                              Icons.check_circle_outline_rounded,
                                              size: 16,
                                            ),
                                            label: const Text('Đánh dấu Đi làm'),
                                          ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: !isWorking
                                        ? FilledButton.icon(
                                            style: FilledButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFFDC2626,
                                              ),
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                            onPressed: () =>
                                                _setWorkingStatus(emp, false),
                                            icon: const Icon(
                                              Icons.pause_circle_filled_rounded,
                                              size: 16,
                                            ),
                                            label: const Text('Đang nghỉ'),
                                          )
                                        : OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: const Color(
                                                0xFFDC2626,
                                              ),
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                            onPressed: () =>
                                                _setWorkingStatus(emp, false),
                                            icon: const Icon(
                                              Icons.pause_circle_outline_rounded,
                                              size: 16,
                                            ),
                                            label: const Text('Đánh dấu Nghỉ'),
                                          ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );

    if (widget.embedded) return body;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Chấm công cho Nhân viên')),
      body: body,
    );
  }
}

class _AttendanceCountBadge extends StatelessWidget {
  const _AttendanceCountBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 3.2. CHỨC NĂNG CON 2: QUẢN LÝ TÀI KHOẢN NHÂN VIÊN
//      (Xem, tìm kiếm, sửa Tên, Email, SĐT, Chức vụ, Nơi làm việc Cửa hàng/Kho)
// =============================================================================

class AdminStaffProfileManagementScreen extends StatefulWidget {
  const AdminStaffProfileManagementScreen({
    this.embedded = false,
    super.key,
  });

  final bool embedded;

  @override
  State<AdminStaffProfileManagementScreen> createState() =>
      _AdminStaffProfileManagementScreenState();
}

class _AdminStaffProfileManagementScreenState
    extends State<AdminStaffProfileManagementScreen> {
  final EmployeeManagementService _service = EmployeeManagementService();
  final TextEditingController _searchController = TextEditingController();

  List<EmployeeRecord> _employees = [];
  List<BranchLocation> _stores = [];
  List<BranchLocation> _warehouses = [];
  bool _isLoading = true;
  String _roleFilter = 'ALL';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getEmployees(),
        _service.getStores(),
        _service.getWarehouses(),
      ]);
      if (!mounted) return;
      setState(() {
        _employees = results[0] as List<EmployeeRecord>;
        _stores = results[1] as List<BranchLocation>;
        _warehouses = results[2] as List<BranchLocation>;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleActive(EmployeeRecord emp, bool nextActive) async {
    final updated = await _service.toggleEmployeeActive(
      employee: emp,
      isActive: nextActive,
    );
    if (!mounted) return;
    setState(() {
      final idx = _employees.indexWhere((e) => e.id == emp.id);
      if (idx >= 0) _employees[idx] = updated;
    });
    showSmartMartNotice(
      context,
      message: nextActive
          ? 'Đã kích hoạt tài khoản ${emp.fullName}'
          : 'Đã tạm khóa tài khoản ${emp.fullName}',
      icon: nextActive ? Icons.verified_user_rounded : Icons.lock_rounded,
    );
  }

  Future<void> _showEditEmployeeSheet(EmployeeRecord emp) async {
    final nameCtrl = TextEditingController(text: emp.fullName);
    final emailCtrl = TextEditingController(text: emp.email);
    final phoneCtrl = TextEditingController(text: emp.phone);
    String selectedRole = emp.role;
    String? selectedStoreId =
        emp.storeId ?? (_stores.isNotEmpty ? _stores.first.id : null);
    String? selectedWarehouseId =
        emp.warehouseId ??
        (_warehouses.isNotEmpty ? _warehouses.first.id : null);
    bool isActive = emp.isActive;
    bool isSaving = false;

    final updatedRecord = await showModalBottomSheet<EmployeeRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isStoreRole =
              selectedRole == 'store_manager' || selectedRole == 'sales';
          final isWarehouseRole =
              selectedRole == 'kho_manager' || selectedRole == 'kho';

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 14,
              bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.line,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.blue50,
                        child: Icon(
                          Icons.edit_note_rounded,
                          color: AppColors.blue700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Chỉnh sửa Tài khoản Nhân viên',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Mã nhân viên: ${emp.code}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên nhân viên',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ Email đăng nhập',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại liên hệ',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Chức vụ / Vai trò',
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text('Quản trị viên (Admin)'),
                      ),
                      DropdownMenuItem(
                        value: 'store_manager',
                        child: Text('Quản lý Cửa hàng'),
                      ),
                      DropdownMenuItem(
                        value: 'sales',
                        child: Text('Nhân viên Bán hàng'),
                      ),
                      DropdownMenuItem(
                        value: 'kho_manager',
                        child: Text('Quản lý Kho'),
                      ),
                      DropdownMenuItem(
                        value: 'kho',
                        child: Text('Nhân viên Kho'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setSheetState(() => selectedRole = v);
                      }
                    },
                  ),
                  if (isStoreRole && _stores.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _stores.any((s) => s.id == selectedStoreId)
                          ? selectedStoreId
                          : _stores.first.id,
                      decoration: const InputDecoration(
                        labelText: 'Nơi làm việc (Cơ sở Cửa hàng)',
                        prefixIcon: Icon(Icons.storefront_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: _stores
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setSheetState(() => selectedStoreId = v),
                    ),
                  ],
                  if (isWarehouseRole && _warehouses.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _warehouses.any((w) => w.id == selectedWarehouseId)
                          ? selectedWarehouseId
                          : _warehouses.first.id,
                      decoration: const InputDecoration(
                        labelText: 'Nơi làm việc (Cơ sở Kho hàng)',
                        prefixIcon: Icon(Icons.warehouse_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: _warehouses
                          .map(
                            (w) => DropdownMenuItem(
                              value: w.id,
                              child: Text(w.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setSheetState(() => selectedWarehouseId = v),
                    ),
                  ],
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Trạng thái kích hoạt tài khoản',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      isActive
                          ? 'Đang hoạt động (Cho phép đăng nhập hệ thống)'
                          : 'Đang tạm khóa',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: isActive,
                    onChanged: (v) => setSheetState(() => isActive = v),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (nameCtrl.text.trim().isEmpty ||
                                  emailCtrl.text.trim().isEmpty) {
                                return;
                              }
                              setSheetState(() => isSaving = true);
                              final storeObj = _stores
                                  .where((s) => s.id == selectedStoreId)
                                  .firstOrNull;
                              final whObj = _warehouses
                                  .where((w) => w.id == selectedWarehouseId)
                                  .firstOrNull;
                              final saved = await _service.updateEmployee(
                                id: emp.id,
                                fullName: nameCtrl.text.trim(),
                                email: emailCtrl.text.trim(),
                                phone: phoneCtrl.text.trim(),
                                role: selectedRole,
                                storeId: isStoreRole ? selectedStoreId : null,
                                storeName: isStoreRole
                                    ? (storeObj?.name ?? '')
                                    : '',
                                warehouseId: isWarehouseRole
                                    ? selectedWarehouseId
                                    : null,
                                warehouseName: isWarehouseRole
                                    ? (whObj?.name ?? '')
                                    : '',
                                isActive: isActive,
                              );
                              if (sheetCtx.mounted) {
                                Navigator.of(sheetCtx).pop(saved);
                              }
                            },
                      icon: const Icon(Icons.save_rounded),
                      label: Text(
                        isSaving ? 'Đang lưu...' : 'Lưu thông tin nhân viên',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (updatedRecord != null && mounted) {
      setState(() {
        final idx = _employees.indexWhere((e) => e.id == emp.id);
        if (idx >= 0) _employees[idx] = updatedRecord;
      });
      showSmartMartNotice(
        context,
        message: 'Đã cập nhật tài khoản ${updatedRecord.fullName} thành công.',
        icon: Icons.check_circle_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _employees.where((e) {
      if (_roleFilter != 'ALL' && e.role != _roleFilter) return false;
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        return e.fullName.toLowerCase().contains(q) ||
            e.email.toLowerCase().contains(q) ||
            e.phone.toLowerCase().contains(q) ||
            e.code.toLowerCase().contains(q) ||
            e.branchDisplay.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    final body = RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
        children: [
          // Tìm kiếm
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: 'Tìm theo tên, email, SĐT, chức vụ hoặc nơi làm việc...',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.line),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Lọc theo Chức vụ
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _RoleChip(
                  label: 'Tất cả (${_employees.length})',
                  selected: _roleFilter == 'ALL',
                  onTap: () => setState(() => _roleFilter = 'ALL'),
                ),
                const SizedBox(width: 8),
                _RoleChip(
                  label: 'Quản lý Cửa hàng',
                  selected: _roleFilter == 'store_manager',
                  onTap: () => setState(() => _roleFilter = 'store_manager'),
                ),
                const SizedBox(width: 8),
                _RoleChip(
                  label: 'NV Bán hàng',
                  selected: _roleFilter == 'sales',
                  onTap: () => setState(() => _roleFilter = 'sales'),
                ),
                const SizedBox(width: 8),
                _RoleChip(
                  label: 'Quản lý Kho',
                  selected: _roleFilter == 'kho_manager',
                  onTap: () => setState(() => _roleFilter = 'kho_manager'),
                ),
                const SizedBox(width: 8),
                _RoleChip(
                  label: 'NV Kho',
                  selected: _roleFilter == 'kho',
                  onTap: () => setState(() => _roleFilter = 'kho'),
                ),
                const SizedBox(width: 8),
                _RoleChip(
                  label: 'Admin',
                  selected: _roleFilter == 'admin',
                  onTap: () => setState(() => _roleFilter = 'admin'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.line),
              ),
              child: const Center(
                child: Text(
                  'Không tìm thấy tài khoản nhân viên phù hợp.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            )
          else
            ...filtered.map(
              (emp) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.blue50,
                            child: Text(
                              emp.fullName.isNotEmpty
                                  ? emp.fullName[0].toUpperCase()
                                  : 'N',
                              style: const TextStyle(
                                color: AppColors.blue700,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  emp.fullName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${emp.code} • ${emp.roleLabel}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.blue700,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: emp.isActive,
                            onChanged: (v) => _toggleActive(emp, v),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      _InfoRowItem(
                        label: 'Email tài khoản',
                        value: emp.email.isNotEmpty ? emp.email : 'Chưa cập nhật',
                        icon: Icons.email_outlined,
                      ),
                      _InfoRowItem(
                        label: 'Số điện thoại',
                        value: emp.phone.isNotEmpty ? emp.phone : 'Chưa cập nhật',
                        icon: Icons.phone_outlined,
                      ),
                      _InfoRowItem(
                        label: 'Chức vụ',
                        value: emp.roleLabel,
                        icon: Icons.badge_outlined,
                      ),
                      _InfoRowItem(
                        label: 'Nơi làm việc',
                        value: emp.branchDisplay,
                        icon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showEditEmployeeSheet(emp),
                          icon: const Icon(Icons.edit_rounded, size: 17),
                          label: const Text(
                            'Chỉnh sửa Tên, Email, Chức vụ & Nơi làm việc',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.embedded) return body;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Quản lý Tài khoản Nhân viên')),
      body: body,
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

// =============================================================================
// 3.3. CHỨC NĂNG CON 3: TẠO TÀI KHOẢN CHO NHÂN VIÊN (GIAO DIỆN UI)
// =============================================================================

class AdminCreateEmployeeScreen extends StatefulWidget {
  const AdminCreateEmployeeScreen({
    this.embedded = false,
    super.key,
  });

  final bool embedded;

  @override
  State<AdminCreateEmployeeScreen> createState() =>
      _AdminCreateEmployeeScreenState();
}

class _AdminCreateEmployeeScreenState extends State<AdminCreateEmployeeScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String _selectedRole = 'sales';
  String _selectedBranch = 'Cửa hàng SSM4 - Quận 1';
  bool _obscurePassword = true;
  bool _activateImmediately = true;

  static const _storeBranches = <String>[
    'Cửa hàng SSM4 - Quận 1',
    'Cửa hàng SSM4 - Thủ Đức',
    'Cửa hàng SSM4 - Quận 7',
  ];

  static const _warehouseBranches = <String>[
    'Kho Trung Tâm Thủ Đức',
    'Kho Tổng Nam Sài Gòn (Q7)',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  List<String> get _currentBranches {
    if (_selectedRole == 'kho_manager' || _selectedRole == 'kho') {
      return _warehouseBranches;
    }
    return _storeBranches;
  }

  void _handlePreviewSubmit() {
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty) {
      showSmartMartNotice(
        context,
        message: 'Vui lòng nhập đầy đủ Họ tên và Email nhân viên.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }
    showSmartMartNotice(
      context,
      message:
          'Đã ghi nhận biểu mẫu tạo tài khoản cho ${_nameCtrl.text.trim()} (${EmployeeRecord.labelForRole(_selectedRole)}).',
      icon: Icons.person_add_alt_1_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdminRole = _selectedRole == 'admin';
    final branches = _currentBranches;
    if (!branches.contains(_selectedBranch)) {
      _selectedBranch = branches.first;
    }

    final body = ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
      children: [
        // Thẻ xem trước hồ sơ nhân viên mới
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: Color(0x33FFFFFF),
                child: Icon(
                  Icons.person_add_alt_1_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BIỂU MẪU CẤP TÀI KHOẢN MỚI',
                      style: TextStyle(
                        color: Color(0xFFDDD6FE),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _nameCtrl.text.trim().isEmpty
                          ? 'Họ và tên nhân viên mới'
                          : _nameCtrl.text.trim(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${EmployeeRecord.labelForRole(_selectedRole)} • ${isAdminRole ? "Trụ sở chính SSM4" : _selectedBranch}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '1. Thông tin Cá nhân & Đăng nhập',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _nameCtrl,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Họ và tên nhân viên *',
                  hintText: 'VD: Nguyễn Văn An',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email tài khoản *',
                  hintText: 'VD: an.nguyen@ssm4.vn',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại liên hệ',
                  hintText: 'VD: 0901234567',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu khởi tạo *',
                  hintText: 'Tối thiểu 6 ký tự',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '2. Phân quyền Chức vụ & Nơi làm việc',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Chức vụ trong hệ thống',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'sales',
                    child: Text('Nhân viên Bán hàng (POS)'),
                  ),
                  DropdownMenuItem(
                    value: 'store_manager',
                    child: Text('Quản lý Cửa hàng'),
                  ),
                  DropdownMenuItem(
                    value: 'kho',
                    child: Text('Nhân viên Kho hàng'),
                  ),
                  DropdownMenuItem(
                    value: 'kho_manager',
                    child: Text('Quản lý Kho hàng'),
                  ),
                  DropdownMenuItem(
                    value: 'admin',
                    child: Text('Quản trị viên (Admin)'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _selectedRole = v);
                  }
                },
              ),
              if (!isAdminRole) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedBranch,
                  decoration: InputDecoration(
                    labelText:
                        (_selectedRole == 'kho_manager' ||
                            _selectedRole == 'kho')
                        ? 'Phân công về Cơ sở Kho hàng'
                        : 'Phân công về Cơ sở Cửa hàng',
                    prefixIcon: const Icon(Icons.location_city_rounded),
                    border: const OutlineInputBorder(),
                  ),
                  items: branches
                      .map(
                        (b) => DropdownMenuItem(
                          value: b,
                          child: Text(b),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _selectedBranch = v);
                    }
                  },
                ),
              ],
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Kích hoạt tài khoản ngay sau khi tạo',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Cho phép nhân viên đăng nhập vào ứng dụng ngay lập tức',
                  style: TextStyle(fontSize: 12),
                ),
                value: _activateImmediately,
                onChanged: (v) => setState(() => _activateImmediately = v),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _handlePreviewSubmit,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Tạo Tài khoản Nhân viên'),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) return body;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Tạo Tài khoản Nhân viên')),
      body: body,
    );
  }
}

// =============================================================================
// 4. PHÂN HỆ 05: QUẢN LÝ THỐNG KÊ (LƯỢNG HÀNG & LƯỢNG BÁN / XUẤT CỦA KHO & CỬA HÀNG)
// =============================================================================

class AdminStatisticsScreen extends StatefulWidget {
  const AdminStatisticsScreen({super.key});

  @override
  State<AdminStatisticsScreen> createState() => _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends State<AdminStatisticsScreen> {
  final EmployeeManagementService _service = EmployeeManagementService();
  final TextEditingController _searchController = TextEditingController();

  List<FacilityStatisticsRecord> _records = [];
  bool _isLoading = true;
  String _typeFilter = 'ALL'; // 'ALL' | 'STORE' | 'WAREHOUSE'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    try {
      final list = await _service.getFacilityStatistics();
      if (!mounted) return;
      setState(() {
        _records = list;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _records.where((r) {
      if (_typeFilter != 'ALL' && r.facilityType != _typeFilter) return false;
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        return r.facilityName.toLowerCase().contains(q) ||
            r.address.toLowerCase().contains(q) ||
            r.managerName.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    final storeList = _records.where((r) => r.isStore).toList();
    final whList = _records.where((r) => r.isWarehouse).toList();

    final totalStoreStock =
        storeList.fold<int>(0, (s, r) => s + r.stockQuantity);
    final totalWhStock = whList.fold<int>(0, (s, r) => s + r.stockQuantity);
    final totalSold =
        storeList.fold<int>(0, (s, r) => s + r.soldOrExportedQuantity);
    final totalExported =
        whList.fold<int>(0, (s, r) => s + r.soldOrExportedQuantity);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Quản lý Thống kê Cơ sở'),
        actions: [
          IconButton(
            onPressed: _loadStatistics,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStatistics,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
          children: [
            // Banner tổng hợp lượng hàng & lượng bán toàn hệ thống
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.blue900, AppColors.blue700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'THỐNG KÊ LƯỢNG HÀNG & LƯỢNG BÁN TOÀN CHUỖI',
                    style: TextStyle(
                      color: Color(0xFFFFD58A),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${storeList.length} Cửa hàng & ${whList.length} Kho trung tâm',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _StatBannerBox(
                          label: 'Tồn kệ Cửa hàng',
                          value: '$totalStoreStock SP',
                          sub: 'Đã bán: $totalSold SP',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatBannerBox(
                          label: 'Tồn dự trữ Kho',
                          value: '$totalWhStock SP',
                          sub: 'Đã xuất: $totalExported SP',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Tìm kiếm cơ sở
            TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'Tìm cơ sở kho hoặc cửa hàng...',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Bộ lọc Tất cả / Cửa hàng / Kho hàng
            Row(
              children: [
                _PeriodFilterChip(
                  label: 'Tất cả cơ sở (${_records.length})',
                  selected: _typeFilter == 'ALL',
                  onTap: () => setState(() => _typeFilter = 'ALL'),
                ),
                const SizedBox(width: 8),
                _PeriodFilterChip(
                  label: 'Cửa hàng (${storeList.length})',
                  selected: _typeFilter == 'STORE',
                  onTap: () => setState(() => _typeFilter = 'STORE'),
                ),
                const SizedBox(width: 8),
                _PeriodFilterChip(
                  label: 'Kho hàng (${whList.length})',
                  selected: _typeFilter == 'WAREHOUSE',
                  onTap: () => setState(() => _typeFilter = 'WAREHOUSE'),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ...filtered.map(
                (rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _FacilityStatisticsCard(record: rec),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatBannerBox extends StatelessWidget {
  const _StatBannerBox({
    required this.label,
    required this.value,
    required this.sub,
  });

  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              color: Color(0xFF6EE7B7),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FacilityStatisticsCard extends StatelessWidget {
  const _FacilityStatisticsCard({required this.record});

  final FacilityStatisticsRecord record;

  @override
  Widget build(BuildContext context) {
    final isStore = record.isStore;
    final accent = isStore ? const Color(0xFFEA580C) : const Color(0xFF059669);
    final tint = isStore ? const Color(0xFFFFF7ED) : const Color(0xFFECFDF5);
    final capPct = (record.capacityRatio * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isStore ? Icons.storefront_rounded : Icons.warehouse_rounded,
                  color: accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tint,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isStore ? 'CƠ SỞ CỬA HÀNG' : 'CƠ SỞ KHO HÀNG',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: accent,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '+${record.growthPercent.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.facilityName,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      'QL: ${record.managerName} • ${record.staffCount} nhân viên',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4 chỉ số Lượng hàng & Lượng bán/xuất
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MiniStatCol(
                        label: isStore
                            ? 'Lượng hàng tồn kệ'
                            : 'Lượng hàng tồn kho',
                        value: '${record.stockQuantity} SP',
                        sub:
                            '${record.skuCount} mã SKU • ${record.lowStockCount} sắp hết',
                        color: AppColors.blue900,
                      ),
                    ),
                    Container(width: 1, height: 36, color: AppColors.line),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MiniStatCol(
                        label: isStore
                            ? 'Lượng bán ra (tháng)'
                            : 'Lượng xuất điều phối',
                        value: '${record.soldOrExportedQuantity} SP',
                        sub: isStore
                            ? '${record.orderOrExportCount} đơn hàng'
                            : '${record.orderOrExportCount} phiếu nhập/xuất',
                        color: accent,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStatCol(
                        label: 'Lượng hàng nhập vào',
                        value: '${record.inboundQuantity} SP',
                        sub: 'Tiếp nhận trong kỳ',
                        color: const Color(0xFF059669),
                      ),
                    ),
                    Container(width: 1, height: 36, color: AppColors.line),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MiniStatCol(
                        label: isStore
                            ? 'Doanh thu bán hàng'
                            : 'Giá trị hàng tồn kho',
                        value: formatCurrency(record.revenueOrStockValue),
                        sub: isStore ? 'Tổng doanh thu kỳ' : 'Giá trị ước tính',
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tỷ lệ lấp đầy sức chứa (${record.stockQuantity}/${record.maxCapacity} SP)',
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
              Text(
                '$capPct%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: record.capacityRatio,
              minHeight: 6,
              backgroundColor: tint,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          if (record.topProducts.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Mặt hàng chủ lực: ${record.topProducts.take(3).join(" • ")}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStatCol extends StatelessWidget {
  const _MiniStatCol({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  final String label;
  final String value;
  final String sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          sub,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
        ),
      ],
    );
  }
}

// =============================================================================
// 5. TAB "CÁ NHÂN" TRÊN THANH ĐIỀU HƯỚNG DƯỚI CÙNG CỦA ADMIN
// =============================================================================

class AdminPersonalProfileScreen extends StatefulWidget {
  const AdminPersonalProfileScreen({
    required this.userName,
    required this.userEmail,
    required this.onLogout,
    super.key,
  });

  final String userName;
  final String userEmail;
  final VoidCallback onLogout;

  @override
  State<AdminPersonalProfileScreen> createState() =>
      _AdminPersonalProfileScreenState();
}

class _AdminPersonalProfileScreenState
    extends State<AdminPersonalProfileScreen> {
  final EmployeeManagementService _service = EmployeeManagementService();
  EmployeeRecord? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final p = await _service.getStaffProfile();
      if (!mounted) return;
      setState(() {
        _profile = p;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _showEditProfileDialog() async {
    final nameCtrl = TextEditingController(
      text: _profile?.fullName ?? widget.userName,
    );
    final phoneCtrl = TextEditingController(
      text: _profile?.phone ?? '0901112222',
    );
    final emailCtrl = TextEditingController(
      text: _profile?.email.isNotEmpty == true
          ? _profile!.email
          : widget.userEmail,
    );

    final saved = await showDialog<EmployeeRecord>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cập nhật Hồ sơ Cá nhân Admin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Họ và tên'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              final updated = await _service.updateStaffProfile(
                fullName: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                notifyShift: true,
                notifyEmail: true,
              );
              if (ctx.mounted) Navigator.of(ctx).pop(updated);
            },
            child: const Text('Lưu thay đổi'),
          ),
        ],
      ),
    );

    if (saved != null && mounted) {
      setState(() => _profile = saved);
      showSmartMartNotice(
        context,
        message: 'Đã cập nhật thông tin cá nhân Admin.',
        icon: Icons.check_circle_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _profile?.fullName.isNotEmpty == true
        ? _profile!.fullName
        : (widget.userName.isNotEmpty ? widget.userName : 'Quản trị viên SSM4');
    final displayEmail = _profile?.email.isNotEmpty == true
        ? _profile!.email
        : widget.userEmail;
    final displayPhone = _profile?.phone.isNotEmpty == true
        ? _profile!.phone
        : '0901 112 222';
    final displayCode = _profile?.code ?? 'NV-ADM-0001';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
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
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: Color(0x33FFFFFF),
                child: Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TÀI KHOẢN CÁ NHÂN ADMIN',
                      style: TextStyle(
                        color: Color(0xFFFFD58A),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayEmail,
                      style: const TextStyle(
                        color: Color(0xFFDCEBFA),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thông tin Hồ sơ Quản trị viên',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const Divider(height: 22),
                _InfoRowItem(
                  label: 'Mã định danh',
                  value: displayCode,
                  icon: Icons.qr_code_rounded,
                ),
                _InfoRowItem(
                  label: 'Họ và tên',
                  value: displayName,
                  icon: Icons.person_outline_rounded,
                ),
                _InfoRowItem(
                  label: 'Email đăng nhập',
                  value: displayEmail,
                  icon: Icons.email_outlined,
                ),
                _InfoRowItem(
                  label: 'Số điện thoại',
                  value: displayPhone,
                  icon: Icons.phone_outlined,
                ),
                _InfoRowItem(
                  label: 'Chức vụ',
                  value: 'Quản trị viên Hệ thống (Admin)',
                  icon: Icons.verified_user_outlined,
                ),
                _InfoRowItem(
                  label: 'Phạm vi quản lý',
                  value: 'Toàn chuỗi Kho & Cửa hàng SSM4',
                  icon: Icons.domain_rounded,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showEditProfileDialog,
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Chỉnh sửa thông tin cá nhân'),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red[700],
            side: BorderSide(color: Colors.red.shade200),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: widget.onLogout,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Đăng xuất tài khoản Admin'),
        ),
      ],
    );
  }
}
