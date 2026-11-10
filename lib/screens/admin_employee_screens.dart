import 'package:flutter/material.dart';

import '../features/suppliers/screens/supplier_list_screen.dart';
import '../models/employee_management_models.dart';
import '../models/store_models.dart';
import '../services/employee_management_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'goods_receipt_screens.dart';

// =============================================================================
// 1. TRANG CHỦ ADMIN (THIẾT KẾ DỰA THEO HOME_SCREEN VỚI QUẢN LÝ DOANH THU CỬA HÀNG)
// =============================================================================

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({
    required this.userName,
    required this.userEmail,
    required this.onOpenMenu,
    required this.onSelectBottomTab,
    required this.onLogout,
    super.key,
  });

  final String userName;
  final String userEmail;
  final VoidCallback onOpenMenu;
  final ValueChanged<int> onSelectBottomTab;
  final VoidCallback onLogout;

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final EmployeeManagementService _service = EmployeeManagementService();
  final TextEditingController _searchController = TextEditingController();

  List<StoreRevenueSummary> _storeRevenues = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _period = 'MONTH'; // 'TODAY' | 'WEEK' | 'MONTH'

  @override
  void initState() {
    super.initState();
    _loadRevenueData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _loadRevenueData() async {
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

  void _showStoreRevenueDetailSheet(StoreRevenueSummary store) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.blue50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: AppColors.blue700,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.storeName,
                          style: const TextStyle(
                            fontSize: 17,
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
              const Divider(height: 24),
              _DetailMetricRow(
                label: 'Quản lý cửa hàng',
                value: store.managerName,
              ),
              _DetailMetricRow(
                label: 'Số điện thoại liên hệ',
                value: store.phone,
              ),
              _DetailMetricRow(
                label: 'Nhân sự đang đi làm hôm nay',
                value: '${store.workingTodayCount}/${store.staffCount} nhân viên',
              ),
              _DetailMetricRow(
                label: 'Doanh thu hôm nay',
                value: formatVnd(store.todayRevenue),
                highlight: true,
              ),
              _DetailMetricRow(
                label: 'Doanh thu 7 ngày qua',
                value: formatVnd(store.weekRevenue),
              ),
              _DetailMetricRow(
                label: 'Doanh thu tháng này',
                value: formatVnd(store.monthRevenue),
                highlight: true,
              ),
              _DetailMetricRow(
                label: 'Chỉ tiêu doanh thu tháng',
                value:
                    '${formatVnd(store.monthlyTarget)} (Đạt ${(store.targetProgress * 100).toStringAsFixed(1)}%)',
              ),
              _DetailMetricRow(
                label: 'Tổng đơn hàng tháng này',
                value: '${store.monthOrders} đơn hàng',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        widget.onSelectBottomTab(3); // Sang tab Chấm công
                      },
                      icon: const Icon(Icons.fact_check_outlined, size: 18),
                      label: const Text('Kiểm tra chấm công'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(sheetCtx),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Đóng'),
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

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final query = _searchQuery.trim().toLowerCase();

    final filteredStores = _storeRevenues.where((s) {
      if (query.isEmpty) return true;
      return s.storeName.toLowerCase().contains(query) ||
          s.address.toLowerCase().contains(query) ||
          s.managerName.toLowerCase().contains(query);
    }).toList();

    final totalRevenue = _storeRevenues.fold<int>(
      0,
      (sum, item) => sum + _revenueForPeriod(item),
    );
    final totalOrders = _storeRevenues.fold<int>(
      0,
      (sum, item) => sum + _ordersForPeriod(item),
    );
    final totalWorking = _storeRevenues.fold<int>(
      0,
      (sum, item) => sum + item.workingTodayCount,
    );
    final totalStaff = _storeRevenues.fold<int>(
      0,
      (sum, item) => sum + item.staffCount,
    );

    return RefreshIndicator(
      color: AppColors.blue700,
      onRefresh: _loadRevenueData,
      child: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _CollapsingAdminHeader(
              userName: widget.userName,
              onOpenMenu: widget.onOpenMenu,
              onRefreshTap: _loadRevenueData,
              onLogoutTap: widget.onLogout,
              searchController: _searchController,
              onSearchChanged: (value) => setState(() => _searchQuery = value),
              topInset: topInset,
              totalRevenue: totalRevenue,
              storeCount: _storeRevenues.length,
              totalOrders: totalOrders,
              periodLabel: _periodLabel,
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              decoration: const BoxDecoration(color: AppColors.canvas),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lối tắt nhanh các chức năng của Admin
                  SectionHeading(
                    title: 'Chức năng Quản trị viên',
                    action: 'Mở Menu Chức năng',
                    onAction: () => widget.onSelectBottomTab(1),
                  ),
                  _AdminQuickFunctionGrid(
                    onSelectBottomTab: widget.onSelectBottomTab,
                  ),
                  const SizedBox(height: 18),

                  // Phần Quản lý doanh thu của các cửa hàng đang có
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Quản lý Doanh thu các Cửa hàng',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      SegmentedButton<String>(
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                        ),
                        segments: const [
                          ButtonSegment(
                            value: 'TODAY',
                            label: Text('Ngày', style: TextStyle(fontSize: 10)),
                          ),
                          ButtonSegment(
                            value: 'WEEK',
                            label: Text('Tuần', style: TextStyle(fontSize: 10)),
                          ),
                          ButtonSegment(
                            value: 'MONTH',
                            label: Text('Tháng', style: TextStyle(fontSize: 10)),
                          ),
                        ],
                        selected: {_period},
                        onSelectionChanged: (s) =>
                            setState(() => _period = s.first),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 3 thẻ chỉ số tổng hợp chuỗi cửa hàng
                  Row(
                    children: [
                      Expanded(
                        child: _AdminKpiMiniCard(
                          label: 'Tổng doanh thu ($_periodLabel)',
                          value: formatVnd(totalRevenue),
                          subValue: '${_storeRevenues.length} cửa hàng hoạt động',
                          icon: Icons.payments_rounded,
                          color: AppColors.blue700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _AdminKpiMiniCard(
                          label: 'Đơn hàng & Nhân sự',
                          value: '$totalOrders đơn',
                          subValue: 'Đi làm: $totalWorking/$totalStaff NV',
                          icon: Icons.receipt_long_rounded,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Thanh so sánh tỷ trọng doanh thu giữa các cửa hàng
                  if (!_isLoading && filteredStores.isNotEmpty) ...[
                    _StoreRevenueShareCard(
                      stores: filteredStores,
                      totalRevenue: totalRevenue,
                      revenueGetter: _revenueForPeriod,
                      periodLabel: _periodLabel,
                    ),
                    const SizedBox(height: 16),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Danh sách Cửa hàng hiện có (${filteredStores.length})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _loadRevenueData,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Làm mới'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (filteredStores.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.store_mall_directory_outlined,
                            size: 40,
                            color: AppColors.muted,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Không tìm thấy cửa hàng phù hợp.',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    )
                  else
                    ...filteredStores.map(
                      (store) => _StoreRevenueCard(
                        store: store,
                        periodRevenue: _revenueForPeriod(store),
                        periodOrders: _ordersForPeriod(store),
                        periodLabel: _periodLabel,
                        onTap: () => _showStoreRevenueDetailSheet(store),
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
}

class _CollapsingAdminHeader extends SliverPersistentHeaderDelegate {
  const _CollapsingAdminHeader({
    required this.userName,
    required this.onOpenMenu,
    required this.onRefreshTap,
    required this.onLogoutTap,
    required this.searchController,
    required this.onSearchChanged,
    required this.topInset,
    required this.totalRevenue,
    required this.storeCount,
    required this.totalOrders,
    required this.periodLabel,
  });

  final String userName;
  final VoidCallback onOpenMenu;
  final VoidCallback onRefreshTap;
  final VoidCallback onLogoutTap;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final double topInset;
  final int totalRevenue;
  final int storeCount;
  final int totalOrders;
  final String periodLabel;

  @override
  double get minExtent => topInset + 100;

  @override
  double get maxExtent => 326 + topInset;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final bottomRadius = Radius.circular(28 - (10 * progress));
    final searchTop = topInset + 80 - 52 * progress;
    final informationTop = topInset + 8 - 25 * progress;

    return Material(
      elevation: overlapsContent ? 3 : 0,
      shadowColor: AppColors.blue900.withValues(alpha: 0.14),
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final blueHeight = (constraints.maxHeight - 84)
                .clamp(minExtent, maxExtent)
                .toDouble();
            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: blueHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.blue900, AppColors.blue700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(bottom: bottomRadius),
                    ),
                  ),
                ),
                // Thẻ Banner Tổng quan Doanh thu Chuỗi Cửa hàng (thay cho PromoBanner)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 0,
                  height: 168,
                  child: Opacity(
                    opacity: (1 - progress * 1.25).clamp(0.0, 1.0),
                    child: IgnorePointer(
                      ignoring: progress > 0.7,
                      child: _AdminSystemRevenueBanner(
                        totalRevenue: totalRevenue,
                        storeCount: storeCount,
                        totalOrders: totalOrders,
                        periodLabel: periodLabel,
                      ),
                    ),
                  ),
                ),
                // Hàng thông tin Admin + Nút mở Menu chức năng Admin (loại bỏ địa chỉ giao hàng)
                Positioned(
                  left: 16,
                  right: 16,
                  top: informationTop,
                  child: Opacity(
                    opacity: (1 - progress * 1.45).clamp(0.0, 1.0),
                    child: IgnorePointer(
                      ignoring: progress > 0.82,
                      child: Row(
                        children: [
                          SmartMartLogo(
                            compact: true,
                            logoSize: 60,
                            onTap: onOpenMenu,
                            onDark: true,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'SSM4 ADMIN',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  userName.isNotEmpty
                                      ? 'Quản trị viên: $userName'
                                      : 'Quản trị hệ thống chuỗi cửa hàng',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFD6E8FF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            tooltip: 'Menu chức năng Admin',
                            onPressed: onOpenMenu,
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.14),
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.menu_rounded),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Đăng xuất',
                            onPressed: onLogoutTap,
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.14),
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.logout_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Thanh tìm kiếm cửa hàng trên trang chủ Admin
                Positioned(
                  left: 16,
                  right: 16,
                  top: searchTop,
                  height: 56,
                  child: SearchField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    hintText: 'Tìm cửa hàng, địa chỉ hoặc người quản lý...',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_CollapsingAdminHeader oldDelegate) =>
      oldDelegate.userName != userName ||
      oldDelegate.totalRevenue != totalRevenue ||
      oldDelegate.storeCount != storeCount ||
      oldDelegate.totalOrders != totalOrders ||
      oldDelegate.periodLabel != periodLabel;
}

class _AdminSystemRevenueBanner extends StatelessWidget {
  const _AdminSystemRevenueBanner({
    required this.totalRevenue,
    required this.storeCount,
    required this.totalOrders,
    required this.periodLabel,
  });

  final int totalRevenue;
  final int storeCount;
  final int totalOrders;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F294A), Color(0xFF1E4E8C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue900.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'DOANH THU CHUỖI CỬA HÀNG • ${periodLabel.toUpperCase()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      color: Colors.greenAccent,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '+12.4%',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Text(
            formatVnd(totalRevenue),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.storefront_rounded,
                color: Color(0xFFD6E8FF),
                size: 16,
              ),
              const SizedBox(width: 5),
              Text(
                '$storeCount cửa hàng đang hoạt động',
                style: const TextStyle(
                  color: Color(0xFFD6E8FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.shopping_bag_outlined,
                color: Color(0xFFFFD58A),
                size: 15,
              ),
              const SizedBox(width: 4),
              Text(
                '$totalOrders đơn hoàn tất',
                style: const TextStyle(
                  color: Color(0xFFFFD58A),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminQuickFunctionGrid extends StatelessWidget {
  const _AdminQuickFunctionGrid({required this.onSelectBottomTab});

  final ValueChanged<int> onSelectBottomTab;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, Color, Color, VoidCallback)>[
      (
        Icons.badge_rounded,
        'Quản lý hồ sơ\nnhân viên',
        const Color(0xFFEFF6FF),
        AppColors.blue700,
        () => onSelectBottomTab(2),
      ),
      (
        Icons.fact_check_rounded,
        'Chấm công\nnhân viên',
        const Color(0xFFF0FDF4),
        const Color(0xFF15803D),
        () => onSelectBottomTab(3),
      ),
      (
        Icons.person_add_alt_1_rounded,
        'Tạo tài khoản\nnhân viên',
        const Color(0xFFF5F3FF),
        const Color(0xFF6D28D9),
        () => onSelectBottomTab(4),
      ),
      (
        Icons.business_rounded,
        'Quản lý\nnhà cung cấp',
        const Color(0xFFFFFBEB),
        const Color(0xFFB45309),
        () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SupplierListScreen(userRole: 'ADMIN'),
            ),
          );
        },
      ),
      (
        Icons.inventory_2_rounded,
        'Nhập hàng từ\nnhà cung cấp',
        const Color(0xFFECFEFF),
        const Color(0xFF0E7490),
        () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const GoodsReceiptsScreen(userRole: 'ADMIN'),
            ),
          );
        },
      ),
      (
        Icons.add_circle_outline_rounded,
        'Tạo phiếu\nnhập kho mới',
        const Color(0xFFFFF1F2),
        const Color(0xFFBE123C),
        () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CreateGoodsReceiptScreen(userRole: 'ADMIN'),
            ),
          );
        },
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: item.$5,
          child: Ink(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: item.$3,
                  child: Icon(item.$1, color: item.$4, size: 22),
                ),
                const SizedBox(height: 7),
                Text(
                  item.$2,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AdminKpiMiniCard extends StatelessWidget {
  const _AdminKpiMiniCard({
    required this.label,
    required this.value,
    required this.subValue,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String subValue;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subValue,
            style: const TextStyle(fontSize: 10, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _StoreRevenueShareCard extends StatelessWidget {
  const _StoreRevenueShareCard({
    required this.stores,
    required this.totalRevenue,
    required this.revenueGetter,
    required this.periodLabel,
  });

  final List<StoreRevenueSummary> stores;
  final int totalRevenue;
  final int Function(StoreRevenueSummary) revenueGetter;
  final String periodLabel;

  static const _barColors = <Color>[
    AppColors.blue700,
    Color(0xFF15803D),
    Color(0xFFB45309),
    Color(0xFF6D28D9),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tỷ trọng doanh thu theo cửa hàng ($periodLabel)',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...List.generate(stores.length, (index) {
            final store = stores[index];
            final rev = revenueGetter(store);
            final ratio = totalRevenue <= 0
                ? 0.0
                : (rev / totalRevenue).clamp(0.0, 1.0);
            final color = _barColors[index % _barColors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          store.storeName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${formatVnd(rev)} (${(ratio * 100).toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 8,
                      backgroundColor: AppColors.blue50,
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StoreRevenueCard extends StatelessWidget {
  const _StoreRevenueCard({
    required this.store,
    required this.periodRevenue,
    required this.periodOrders,
    required this.periodLabel,
    required this.onTap,
  });

  final StoreRevenueSummary store;
  final int periodRevenue;
  final int periodOrders;
  final String periodLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.blue50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: AppColors.blue700,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.storeName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          store.address,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '+${store.growthPercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
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
                        formatVnd(periodRevenue),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.blue800,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Số đơn / Nhân sự trực',
                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$periodOrders đơn • ${store.workingTodayCount}/${store.staffCount} NV',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: store.targetProgress,
                        minHeight: 6,
                        backgroundColor: AppColors.blue50,
                        color: AppColors.blue700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'KPI tháng: ${(store.targetProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
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

class _DetailMetricRow extends StatelessWidget {
  const _DetailMetricRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: highlight ? FontWeight.w900 : FontWeight.w700,
              color: highlight ? AppColors.blue800 : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 2. MÀN HÌNH MENU CÁC CHỨC NĂNG CỦA ADMIN (TRONG THANH ĐIỀU HƯỚNG DƯỚI)
// =============================================================================

class AdminFunctionsMenuScreen extends StatelessWidget {
  const AdminFunctionsMenuScreen({
    required this.onSelectBottomTab,
    super.key,
  });

  final ValueChanged<int> onSelectBottomTab;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
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
          child: const Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white24,
                child: Icon(
                  Icons.apps_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DANH MỤC CHỨC NĂNG ADMIN',
                      style: TextStyle(
                        color: Color(0xFFD6E8FF),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Quản lý Chuỗi cung ứng & Nhân sự',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Quản lý Nhà cung cấp & Nhập kho',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        _AdminFunctionMenuTile(
          icon: Icons.business_rounded,
          title: 'Quản lý nhà cung cấp',
          subtitle: 'Xem danh sách, tìm kiếm và thêm nhà cung cấp mới',
          tint: const Color(0xFFEFF6FF),
          iconColor: AppColors.blue700,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SupplierListScreen(
                  userRole: 'ADMIN',
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _AdminFunctionMenuTile(
          icon: Icons.inventory_2_rounded,
          title: 'Nhập hàng từ nhà cung cấp',
          subtitle: 'Xem tất cả phiếu nhập toàn hệ thống, theo dõi tiến độ',
          tint: const Color(0xFFF0FDF4),
          iconColor: const Color(0xFF15803D),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const GoodsReceiptsScreen(
                  userRole: 'ADMIN',
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _AdminFunctionMenuTile(
          icon: Icons.add_circle_outline_rounded,
          title: 'Tạo phiếu nhập kho mới',
          subtitle: 'Lập phiếu nhập hàng từ nhà cung cấp vào kho được chọn',
          tint: const Color(0xFFFFFBEB),
          iconColor: const Color(0xFFB45309),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CreateGoodsReceiptScreen(
                  userRole: 'ADMIN',
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        const Text(
          'Quản lý Nhân sự & Chấm công',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        _AdminFunctionMenuTile(
          icon: Icons.badge_rounded,
          title: 'Quản lý hồ sơ nhân viên',
          subtitle:
              'Xem và sửa thông tin nhân viên: Tên, Email, SĐT, Chức vụ (Role), Cơ sở làm việc',
          tint: const Color(0xFFEFF6FF),
          iconColor: AppColors.blue700,
          onTap: () => onSelectBottomTab(2),
        ),
        const SizedBox(height: 10),
        _AdminFunctionMenuTile(
          icon: Icons.fact_check_rounded,
          title: 'Chấm công cho nhân viên',
          subtitle:
              'Quản lý số ngày công đã chấm, danh sách nhân viên theo từng cơ sở, đánh dấu đang đi làm / không đi làm',
          tint: const Color(0xFFF0FDF4),
          iconColor: const Color(0xFF15803D),
          onTap: () => onSelectBottomTab(3),
        ),
        const SizedBox(height: 10),
        _AdminFunctionMenuTile(
          icon: Icons.person_add_alt_1_rounded,
          title: 'Tạo tài khoản cho nhân viên',
          subtitle:
              'Tạo tài khoản đăng nhập mới cho nhân viên và phân công về Cửa hàng / Kho',
          tint: const Color(0xFFF5F3FF),
          iconColor: const Color(0xFF6D28D9),
          onTap: () => onSelectBottomTab(4),
        ),
      ],
    );
  }
}

class _AdminFunctionMenuTile extends StatelessWidget {
  const _AdminFunctionMenuTile({
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
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: tint,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
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
// 3. QUẢN LÝ HỒ SƠ NHÂN VIÊN (XEM & SỬA TÊN, EMAIL, SĐT, CHỨC VỤ ROLE, CƠ SỞ LÀM VIỆC)
// =============================================================================

class AdminStaffProfileManagementScreen extends StatefulWidget {
  const AdminStaffProfileManagementScreen({super.key});

  @override
  State<AdminStaffProfileManagementScreen> createState() =>
      _AdminStaffProfileManagementScreenState();
}

class _AdminStaffProfileManagementScreenState
    extends State<AdminStaffProfileManagementScreen> {
  final EmployeeManagementService _service = EmployeeManagementService();

  List<EmployeeRecord> _employees = [];
  List<BranchLocation> _stores = [];
  List<BranchLocation> _warehouses = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _roleFilter = 'ALL';
  String _facilityFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getStores(),
        _service.getWarehouses(),
        _service.getEmployees(),
      ]);
      if (!mounted) return;
      setState(() {
        _stores = results[0] as List<BranchLocation>;
        _warehouses = results[1] as List<BranchLocation>;
        _employees = results[2] as List<EmployeeRecord>;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<EmployeeRecord> get _filteredEmployees {
    final q = _searchQuery.trim().toLowerCase();
    return _employees.where((e) {
      if (_roleFilter != 'ALL' && e.role != _roleFilter) return false;
      if (_facilityFilter != 'ALL' && e.facilityGroupName != _facilityFilter) {
        return false;
      }
      if (q.isNotEmpty) {
        final match = e.fullName.toLowerCase().contains(q) ||
            e.email.toLowerCase().contains(q) ||
            e.phone.toLowerCase().contains(q) ||
            e.code.toLowerCase().contains(q) ||
            e.branchDisplay.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  List<String> get _facilityNames {
    final set = <String>{};
    for (final e in _employees) {
      set.add(e.facilityGroupName);
    }
    return set.toList();
  }

  /// Mở hộp thoại Xem & Sửa thông tin nhân viên:
  /// Tên, Email, SĐT, Chức vụ (liên quan đến role), Cơ sở làm việc.
  Future<void> _showEditEmployeeProfileDialog(EmployeeRecord emp) async {
    final nameCtrl = TextEditingController(text: emp.fullName);
    final emailCtrl = TextEditingController(text: emp.email);
    final phoneCtrl = TextEditingController(text: emp.phone);

    String selectedRole = emp.role;
    String? selectedStoreId =
        emp.storeId ?? (_stores.isNotEmpty ? _stores.first.id : null);
    String? selectedWarehouseId =
        emp.warehouseId ?? (_warehouses.isNotEmpty ? _warehouses.first.id : null);
    bool isActive = emp.isActive;
    bool isSaving = false;
    String? errorMsg;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isStoreRole =
              selectedRole == 'store_manager' || selectedRole == 'sales';
          final isWarehouseRole =
              selectedRole == 'kho_manager' || selectedRole == 'kho';

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.edit_note_rounded, color: AppColors.blue700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sửa hồ sơ: ${emp.fullName}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (errorMsg != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          errorMsg!,
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên nhân viên *',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email công việc *',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại *',
                        prefixIcon: Icon(Icons.phone_android_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Chức vụ (Role hệ thống) *',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedRole,
                          isDense: true,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: 'sales',
                              child: Text('Nhân viên Bán hàng (sales)'),
                            ),
                            DropdownMenuItem(
                              value: 'store_manager',
                              child: Text('Quản lý Cửa hàng (store_manager)'),
                            ),
                            DropdownMenuItem(
                              value: 'kho',
                              child: Text('Nhân viên Kho (kho)'),
                            ),
                            DropdownMenuItem(
                              value: 'kho_manager',
                              child: Text('Quản lý Kho (kho_manager)'),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('Quản trị viên (admin)'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedRole = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (isStoreRole && _stores.isNotEmpty)
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Cơ sở làm việc (Cửa hàng) *',
                          prefixIcon: Icon(Icons.storefront_rounded),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _stores.any((s) => s.id == selectedStoreId)
                                ? selectedStoreId
                                : _stores.first.id,
                            isDense: true,
                            isExpanded: true,
                            items: _stores
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text(s.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setDialogState(() => selectedStoreId = val),
                          ),
                        ),
                      ),
                    if (isWarehouseRole && _warehouses.isNotEmpty)
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Cơ sở làm việc (Kho hàng) *',
                          prefixIcon: Icon(Icons.warehouse_rounded),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _warehouses
                                    .any((w) => w.id == selectedWarehouseId)
                                ? selectedWarehouseId
                                : _warehouses.first.id,
                            isDense: true,
                            isExpanded: true,
                            items: _warehouses
                                .map(
                                  (w) => DropdownMenuItem(
                                    value: w.id,
                                    child: Text(w.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setDialogState(() => selectedWarehouseId = val),
                          ),
                        ),
                      ),
                    if (selectedRole == 'admin')
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.blue50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Cơ sở làm việc: Toàn hệ thống (Trụ sở chính SSM4)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.blue800,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Trạng thái tài khoản hoạt động',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        isActive ? 'Đang kích hoạt' : 'Đang tạm khóa',
                        style: const TextStyle(fontSize: 11),
                      ),
                      value: isActive,
                      onChanged: (val) => setDialogState(() => isActive = val),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                child: const Text('Hủy'),
              ),
              FilledButton.icon(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (nameCtrl.text.trim().isEmpty ||
                            emailCtrl.text.trim().isEmpty) {
                          setDialogState(() {
                            errorMsg = 'Vui lòng nhập đầy đủ Tên và Email.';
                          });
                          return;
                        }
                        setDialogState(() {
                          isSaving = true;
                          errorMsg = null;
                        });
                        try {
                          final updated = await _service.updateEmployee(
                            id: emp.id,
                            fullName: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            role: selectedRole,
                            storeId: isStoreRole ? selectedStoreId : null,
                            warehouseId:
                                isWarehouseRole ? selectedWarehouseId : null,
                            isActive: isActive,
                          );
                          if (!dialogCtx.mounted) return;
                          Navigator.pop(dialogCtx);
                          if (!mounted) return;
                          setState(() {
                            final idx = _employees
                                .indexWhere((item) => item.id == emp.id);
                            if (idx >= 0) {
                              _employees[idx] = updated;
                            }
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Đã cập nhật hồ sơ nhân viên ${updated.fullName}!',
                              ),
                              backgroundColor: Colors.green[700],
                            ),
                          );
                        } catch (e) {
                          setDialogState(() {
                            isSaving = false;
                            errorMsg = e.toString();
                          });
                        }
                      },
                icon: const Icon(Icons.save_rounded, size: 18),
                label: Text(isSaving ? 'Đang lưu...' : 'Lưu thông tin'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredEmployees;
    final facilities = _facilityNames;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // Header tóm tắt
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.blue900, AppColors.blue700],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.badge_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quản lý Hồ sơ Nhân viên',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tổng cộng ${_employees.length} nhân sự • Xem & sửa Tên, Email, SĐT, Chức vụ, Cơ sở',
                        style: const TextStyle(
                          color: Color(0xFFD6E8FF),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tìm kiếm
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: const InputDecoration(
              hintText: 'Tìm theo tên, email, SĐT, mã nhân viên hoặc cơ sở...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 10),

          // Bộ lọc Chức vụ & Cơ sở làm việc
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Lọc theo Chức vụ',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _roleFilter,
                      isDense: true,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'ALL',
                          child: Text('Tất cả chức vụ', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 'store_manager',
                          child: Text('Quản lý Cửa hàng', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 'sales',
                          child: Text('NV Bán hàng', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 'kho_manager',
                          child: Text('Quản lý Kho', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 'kho',
                          child: Text('NV Kho', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('Quản trị viên', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _roleFilter = v);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Cơ sở làm việc',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: facilities.contains(_facilityFilter)
                          ? _facilityFilter
                          : 'ALL',
                      isDense: true,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(
                          value: 'ALL',
                          child: Text('Tất cả cơ sở', style: TextStyle(fontSize: 12)),
                        ),
                        ...facilities.map(
                          (f) => DropdownMenuItem(
                            value: f,
                            child: Text(
                              f,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _facilityFilter = v);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(
                child: Text(
                  'Không tìm thấy hồ sơ nhân viên phù hợp.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            )
          else
            ...list.map(
              (emp) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: AppColors.line),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.blue50,
                            child: Text(
                              emp.fullName.isNotEmpty
                                  ? emp.fullName[0].toUpperCase()
                                  : 'N',
                              style: const TextStyle(
                                color: AppColors.blue800,
                                fontWeight: FontWeight.w800,
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
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Mã NV: ${emp.code}  •  Role: ${emp.role}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: emp.isActive
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              emp.isActive ? 'Hoạt động' : 'Đã khóa',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: emp.isActive
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 18),
                      _ProfileFieldLine(
                        icon: Icons.badge_outlined,
                        label: 'Chức vụ',
                        value: emp.roleLabel,
                      ),
                      _ProfileFieldLine(
                        icon: Icons.location_city_rounded,
                        label: 'Cơ sở làm việc',
                        value: emp.branchDisplay,
                      ),
                      _ProfileFieldLine(
                        icon: Icons.mail_outline_rounded,
                        label: 'Email',
                        value: emp.email.isNotEmpty ? emp.email : 'Chưa cập nhật',
                      ),
                      _ProfileFieldLine(
                        icon: Icons.phone_android_rounded,
                        label: 'Số điện thoại',
                        value: emp.phone.isNotEmpty ? emp.phone : 'Chưa cập nhật',
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: () => _showEditEmployeeProfileDialog(emp),
                          icon: const Icon(Icons.edit_rounded, size: 17),
                          label: const Text(
                            'Xem & Sửa thông tin nhân viên',
                            style: TextStyle(fontWeight: FontWeight.w700),
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
  }
}

class _ProfileFieldLine extends StatelessWidget {
  const _ProfileFieldLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.blue700),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 4. CHẤM CÔNG CHO NHÂN VIÊN:
//    - Quản lý số ngày công nhân viên đó đã chấm công
//    - Hiển thị danh sách nhân viên đang làm việc theo từng cơ sở
//    - Có nút đánh dấu Đang đi làm / Không đi làm để kiểm soát nhân viên
// =============================================================================

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  final EmployeeManagementService _service = EmployeeManagementService();

  List<EmployeeRecord> _employees = [];
  Map<String, bool> _workingTodayByEmpId = {};
  Map<String, TimesheetPayrollRecord> _timesheetByEmpId = {};
  bool _isLoading = true;
  String _selectedFacility = 'ALL';
  String _searchQuery = '';
  DateTime _selectedDate = DateTime.now();

  String get _monthKey =>
      '${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _loadAttendanceData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getEmployees(),
        _service.getShifts(startDate: _selectedDate, endDate: _selectedDate),
        _service.getTimesheets(monthYear: _monthKey),
      ]);
      if (!mounted) return;
      final emps = results[0] as List<EmployeeRecord>;
      final shifts = results[1] as List<WorkShiftRecord>;
      final timesheets = results[2] as List<TimesheetPayrollRecord>;

      final workingMap = <String, bool>{};
      for (final emp in emps) {
        final shift =
            shifts.where((s) => s.employeeId == emp.id).firstOrNull;
        workingMap[emp.id] =
            shift != null ? shift.shiftCode != 'OFF' : emp.isActive;
      }

      final tsMap = <String, TimesheetPayrollRecord>{};
      for (final ts in timesheets) {
        tsMap[ts.employeeId] = ts;
      }

      setState(() {
        _employees = emps;
        _workingTodayByEmpId = workingMap;
        _timesheetByEmpId = tsMap;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  int _workDaysOf(EmployeeRecord emp) {
    return _timesheetByEmpId[emp.id]?.workDays ?? 22;
  }

  /// Đánh dấu nhân viên Đang đi làm (`true`) hoặc Không đi làm (`false`)
  /// đồng thời tự động cập nhật số ngày công của nhân viên đó.
  Future<void> _setWorkingStatus(EmployeeRecord emp, bool isWorking) async {
    final prev = _workingTodayByEmpId[emp.id] ?? true;
    if (prev == isWorking) return;

    final currentDays = _workDaysOf(emp);
    final nextDays = isWorking
        ? (currentDays + 1).clamp(0, 31)
        : (currentDays - 1).clamp(0, 31);

    setState(() {
      _workingTodayByEmpId[emp.id] = isWorking;
      final existingTs = _timesheetByEmpId[emp.id];
      if (existingTs != null) {
        _timesheetByEmpId[emp.id] = existingTs.copyWith(
          workDays: nextDays,
          totalHours: nextDays * 8.0,
        );
      }
    });

    try {
      final ts = _timesheetByEmpId[emp.id];
      final syncedDays = await _service.markAttendanceStatus(
        employee: emp,
        workDate: _selectedDate,
        monthYear: _monthKey,
        isWorking: isWorking,
        nextWorkDays: nextDays,
        currentTimesheet: ts,
      );
      if (mounted && ts != null) {
        setState(() {
          _timesheetByEmpId[emp.id] = ts.copyWith(
            workDays: syncedDays,
            totalHours: syncedDays * 8.0,
          );
        });
      }
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(
          isWorking
              ? 'Đã đánh dấu ${emp.fullName}: ĐANG ĐI LÀM (Tổng công: $nextDays ngày)'
              : 'Đã đánh dấu ${emp.fullName}: KHÔNG ĐI LÀM (Tổng công: $nextDays ngày)',
        ),
        backgroundColor: isWorking ? Colors.green[700] : Colors.orange[800],
      ),
    );
  }

  /// Điều chỉnh trực tiếp số ngày công nhân viên đã chấm công.
  Future<void> _adjustWorkDays(EmployeeRecord emp, int newWorkDays) async {
    final clamped = newWorkDays.clamp(0, 31);
    final ts = _timesheetByEmpId[emp.id];
    if (ts != null) {
      setState(() {
        _timesheetByEmpId[emp.id] = ts.copyWith(
          workDays: clamped,
          totalHours: clamped * 8.0,
        );
      });
    }
    try {
      final updated = await _service.updateEmployeeWorkDays(
        employee: emp,
        monthYear: _monthKey,
        workDays: clamped,
        currentTimesheet: ts,
      );
      if (mounted && updated != null) {
        setState(() => _timesheetByEmpId[emp.id] = updated);
      }
    } catch (_) {}
  }

  Future<void> _showEditWorkDaysDialog(EmployeeRecord emp) async {
    final ctrl = TextEditingController(text: '${_workDaysOf(emp)}');
    final result = await showDialog<int>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Quản lý ngày công: ${emp.fullName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cơ sở: ${emp.facilityGroupName}',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Số ngày công đã chấm trong tháng ($_monthKey)',
                suffixText: 'ngày công',
                prefixIcon: const Icon(Icons.calendar_month_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final val = int.tryParse(ctrl.text.trim());
              if (val != null) Navigator.pop(dialogCtx, val);
            },
            child: const Text('Lưu số ngày công'),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      await _adjustWorkDays(emp, result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã cập nhật số ngày công của ${emp.fullName}: $result ngày công',
          ),
          backgroundColor: AppColors.blue700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final facilities = <String>{
      for (final e in _employees) e.facilityGroupName,
    }.toList();

    final q = _searchQuery.trim().toLowerCase();
    final filtered = _employees.where((e) {
      if (_selectedFacility != 'ALL' &&
          e.facilityGroupName != _selectedFacility) {
        return false;
      }
      if (q.isNotEmpty) {
        return e.fullName.toLowerCase().contains(q) ||
            e.code.toLowerCase().contains(q) ||
            e.roleLabel.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    // Gom nhóm nhân viên theo từng cơ sở làm việc
    final groupedByFacility = <String, List<EmployeeRecord>>{};
    for (final emp in filtered) {
      final group = emp.facilityGroupName;
      groupedByFacility.putIfAbsent(group, () => []).add(emp);
    }

    final workingCount = _employees
        .where((e) => _workingTodayByEmpId[e.id] ?? true)
        .length;
    final absentCount = _employees.length - workingCount;

    return RefreshIndicator(
      onRefresh: _loadAttendanceData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // Thẻ tổng quan chấm công & kiểm soát quân số
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.blue900, AppColors.blue700],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.fact_check_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chấm công & Kiểm soát Nhân viên',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Ngày kiểm soát: ${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year} • Kỳ công $_monthKey',
                            style: const TextStyle(
                              color: Color(0xFFD6E8FF),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2028),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                          _loadAttendanceData();
                        }
                      },
                      icon: const Icon(Icons.calendar_today_rounded, size: 14),
                      label: const Text('Đổi ngày', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _AttendanceCountBadge(
                        label: 'Tổng nhân sự',
                        count: _employees.length,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AttendanceCountBadge(
                        label: 'Đang đi làm',
                        count: workingCount,
                        color: Colors.greenAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AttendanceCountBadge(
                        label: 'Không đi làm',
                        count: absentCount,
                        color: const Color(0xFFFFB4A2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Bộ lọc theo từng cơ sở & Tìm kiếm
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Chọn Cơ sở làm việc',
                    prefixIcon: Icon(Icons.storefront_rounded, size: 18),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: facilities.contains(_selectedFacility)
                          ? _selectedFacility
                          : 'ALL',
                      isDense: true,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(
                          value: 'ALL',
                          child: Text(
                            'Tất cả cơ sở làm việc',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        ...facilities.map(
                          (f) => DropdownMenuItem(
                            value: f,
                            child: Text(
                              f,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedFacility = v);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: const InputDecoration(
              hintText: 'Tìm tên hoặc mã nhân viên trong cơ sở...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 14),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (groupedByFacility.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Không có nhân viên nào trong cơ sở đã chọn.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            )
          else
            ...groupedByFacility.entries.map((entry) {
              final facilityName = entry.key;
              final staffList = entry.value;
              final workingInFacility = staffList
                  .where((e) => _workingTodayByEmpId[e.id] ?? true)
                  .length;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tiêu đề từng Cơ sở làm việc
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.blue50,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(17),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_city_rounded,
                            color: AppColors.blue700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              facilityName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.blue900,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Đi làm: $workingInFacility/${staffList.length} NV',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.blue800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Danh sách nhân viên thuộc Cơ sở này
                    ...staffList.map((emp) {
                      final isWorking = _workingTodayByEmpId[emp.id] ?? true;
                      final workDays = _workDaysOf(emp);

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppColors.line),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 19,
                                  backgroundColor: isWorking
                                      ? Colors.green.shade50
                                      : Colors.red.shade50,
                                  child: Icon(
                                    isWorking
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    color: isWorking
                                        ? Colors.green.shade700
                                        : Colors.red.shade600,
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
                                        emp.fullName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        '${emp.roleLabel} • Mã: ${emp.code}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Quản lý số ngày công nhân viên đã chấm công
                                InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => _showEditWorkDaysDialog(emp),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.blue50,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.blue100,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.calendar_month_rounded,
                                          size: 14,
                                          color: AppColors.blue700,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$workDays ngày công',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.blue800,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.edit_rounded,
                                          size: 12,
                                          color: AppColors.blue700,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Hàng nút đánh dấu Đang đi làm / Không đi làm + Tăng giảm ngày công
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: isWorking
                                          ? Colors.green.shade700
                                          : Colors.grey.shade200,
                                      foregroundColor: isWorking
                                          ? Colors.white
                                          : Colors.black87,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () =>
                                        _setWorkingStatus(emp, true),
                                    icon: const Icon(
                                      Icons.check_circle_outline_rounded,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Đang đi làm',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: !isWorking
                                          ? Colors.red.shade600
                                          : Colors.grey.shade200,
                                      foregroundColor: !isWorking
                                          ? Colors.white
                                          : Colors.black87,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () =>
                                        _setWorkingStatus(emp, false),
                                    icon: const Icon(
                                      Icons.highlight_off_rounded,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Không đi làm',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  tooltip: 'Giảm 1 ngày công',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () =>
                                      _adjustWorkDays(emp, workDays - 1),
                                  icon: const Icon(
                                    Icons.remove_circle_outline_rounded,
                                    size: 20,
                                    color: AppColors.muted,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Tăng 1 ngày công',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () =>
                                      _adjustWorkDays(emp, workDays + 1),
                                  icon: const Icon(
                                    Icons.add_circle_outline_rounded,
                                    size: 20,
                                    color: AppColors.blue700,
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
              );
            }),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
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
          Text(
            label,
            style: const TextStyle(color: Color(0xFFD6E8FF), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 5. TẠO TÀI KHOẢN CHO NHÂN VIÊN
// =============================================================================

class AdminCreateEmployeeScreen extends StatefulWidget {
  const AdminCreateEmployeeScreen({super.key});

  @override
  State<AdminCreateEmployeeScreen> createState() =>
      _AdminCreateEmployeeScreenState();
}

class _AdminCreateEmployeeScreenState extends State<AdminCreateEmployeeScreen> {
  final EmployeeManagementService _service = EmployeeManagementService();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController(text: '123456');

  List<BranchLocation> _stores = [];
  List<BranchLocation> _warehouses = [];
  List<EmployeeRecord> _recentEmployees = [];
  String _selectedRole = 'sales';
  String? _selectedStoreId;
  String? _selectedWarehouseId;
  bool _isSubmitting = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getStores(),
        _service.getWarehouses(),
        _service.getEmployees(),
      ]);
      if (!mounted) return;
      final stores = results[0] as List<BranchLocation>;
      final warehouses = results[1] as List<BranchLocation>;
      final employees = results[2] as List<EmployeeRecord>;
      setState(() {
        _stores = stores;
        _warehouses = warehouses;
        _recentEmployees = employees;
        _selectedStoreId ??= stores.isNotEmpty ? stores.first.id : null;
        _selectedWarehouseId ??=
            warehouses.isNotEmpty ? warehouses.first.id : null;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCreateAccount() async {
    final fullName = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (fullName.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ Họ tên và Email nhân viên.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu cần tối thiểu 6 ký tự.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final isStoreRole =
        _selectedRole == 'store_manager' || _selectedRole == 'sales';
    final isWarehouseRole =
        _selectedRole == 'kho_manager' || _selectedRole == 'kho';

    setState(() => _isSubmitting = true);
    try {
      final created = await _service.createEmployee(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        role: _selectedRole,
        storeId: isStoreRole ? _selectedStoreId : null,
        warehouseId: isWarehouseRole ? _selectedWarehouseId : null,
        isActive: true,
      );
      if (!mounted) return;
      _nameCtrl.clear();
      _emailCtrl.clear();
      _phoneCtrl.clear();
      setState(() {
        _isSubmitting = false;
        _recentEmployees = [created, ..._recentEmployees];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã tạo tài khoản thành công cho ${created.fullName} (${created.roleLabel})!',
          ),
          backgroundColor: Colors.green[700],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tạo tài khoản: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStoreRole =
        _selectedRole == 'store_manager' || _selectedRole == 'sales';
    final isWarehouseRole =
        _selectedRole == 'kho_manager' || _selectedRole == 'kho';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.blue900, AppColors.blue700],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white24,
                child: Icon(
                  Icons.person_add_alt_1_rounded,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tạo Tài khoản cho Nhân viên',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Khởi tạo tài khoản đăng nhập mới và phân công cơ sở làm việc',
                      style: TextStyle(
                        color: Color(0xFFD6E8FF),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.line),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Thông tin tài khoản nhân viên mới',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên nhân viên *',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email đăng nhập *',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại *',
                    prefixIcon: Icon(Icons.phone_android_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu khởi tạo *',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Chức vụ (Role) *',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRole,
                      isDense: true,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'sales',
                          child: Text('Nhân viên Bán hàng (sales)'),
                        ),
                        DropdownMenuItem(
                          value: 'store_manager',
                          child: Text('Quản lý Cửa hàng (store_manager)'),
                        ),
                        DropdownMenuItem(
                          value: 'kho',
                          child: Text('Nhân viên Kho (kho)'),
                        ),
                        DropdownMenuItem(
                          value: 'kho_manager',
                          child: Text('Quản lý Kho (kho_manager)'),
                        ),
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('Quản trị viên (admin)'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedRole = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (isStoreRole && _stores.isNotEmpty)
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Phân công Cửa hàng làm việc *',
                      prefixIcon: Icon(Icons.storefront_rounded),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _stores.any((s) => s.id == _selectedStoreId)
                            ? _selectedStoreId
                            : _stores.first.id,
                        isDense: true,
                        isExpanded: true,
                        items: _stores
                            .map(
                              (s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedStoreId = v),
                      ),
                    ),
                  ),
                if (isWarehouseRole && _warehouses.isNotEmpty)
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Phân công Kho làm việc *',
                      prefixIcon: Icon(Icons.warehouse_rounded),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _warehouses
                                .any((w) => w.id == _selectedWarehouseId)
                            ? _selectedWarehouseId
                            : _warehouses.first.id,
                        isDense: true,
                        isExpanded: true,
                        items: _warehouses
                            .map(
                              (w) => DropdownMenuItem(
                                value: w.id,
                                child: Text(w.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedWarehouseId = v),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : _handleCreateAccount,
                    icon: const Icon(Icons.person_add_rounded),
                    label: Text(
                      _isSubmitting
                          ? 'ĐANG TẠO TÀI KHOẢN...'
                          : 'TẠO TÀI KHOẢN NHÂN VIÊN',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Tài khoản nhân viên trong hệ thống',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
          ..._recentEmployees.take(8).map(
                (emp) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.blue50,
                      child: Text(
                        emp.fullName.isNotEmpty
                            ? emp.fullName[0].toUpperCase()
                            : 'N',
                        style: const TextStyle(
                          color: AppColors.blue800,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    title: Text(
                      emp.fullName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      '${emp.roleLabel} • ${emp.branchDisplay}\n${emp.email}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    isThreeLine: true,
                  ),
                ),
              ),
      ],
    );
  }
}
