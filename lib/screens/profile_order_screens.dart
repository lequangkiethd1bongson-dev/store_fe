import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/store_models.dart';
import '../state/store_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

/// hiển thị lịch sử đơn hàng và cho phép lọc theo trạng thái.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({
    required this.store,
    required this.onOpenProduct,
    super.key,
  });

  final StoreController store;
  final ValueChanged<Product> onOpenProduct;

  /// tạo trạng thái lưu tab đơn hàng đang được chọn.
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  static const _tabs = [
    'Tất cả',
    'Chờ xác nhận',
    'Đang giao',
    'Đã giao',
    'Đã hủy',
  ];
  String _selectedTab = 'Tất cả';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.store.loadOrders();
    });
  }

  /// dựng danh sách đơn phù hợp với tab trạng thái hiện tại.
  @override
  Widget build(BuildContext context) {
    final orders = _demoOrders(widget.store);
    final visible = _selectedTab == 'Tất cả'
        ? orders
        : orders.where((order) => order.status == _selectedTab).toList();
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Đơn hàng',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 47,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _tabs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 18),
            itemBuilder: (context, index) {
              final tab = _tabs[index];
              final selected = tab == _selectedTab;
              return InkWell(
                onTap: () => setState(() => _selectedTab = tab),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: selected
                            ? AppColors.blue700
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    tab,
                    style: TextStyle(
                      color: selected ? AppColors.blue700 : AppColors.muted,
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? const Center(
                  child: Text(
                    'Chưa có đơn hàng ở trạng thái này.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  itemCount: visible.length,
                  itemBuilder: (context, index) => _OrderCard(
                    order: visible[index],
                    onOpenProduct: widget.onOpenProduct,
                    store: widget.store,
                  ),
                ),
        ),
      ],
    );
  }

  /// trả danh sách đơn hàng đã lấy từ backend hoặc đơn hàng mua trong phiên,
  /// kết hợp với một số đơn mẫu nếu danh sách hiện tại đang trống.
  List<StoreOrder> _demoOrders(StoreController store) {
    if (store.orders.isNotEmpty) {
      return store.orders;
    }
    final now = DateTime.now();
    return <StoreOrder>[
      StoreOrder(
        id: 'SM24051608',
        createdAt: now,
        lines: [
          CartLine(product: sampleProducts[0], quantity: 1),
          CartLine(product: sampleProducts[1], quantity: 1),
          CartLine(product: sampleProducts[2], quantity: 1),
        ],
        total: 167500,
        status: 'Đang giao',
      ),
      StoreOrder(
        id: 'SM24051209',
        createdAt: now.subtract(const Duration(days: 2)),
        lines: [
          CartLine(product: sampleProducts[2], quantity: 1),
          CartLine(product: sampleProducts[3], quantity: 1),
          CartLine(product: sampleProducts[4], quantity: 2),
        ],
        total: 354000,
        status: 'Đã giao',
      ),
      StoreOrder(
        id: 'SM24051018',
        createdAt: now.subtract(const Duration(days: 4)),
        lines: [
          CartLine(product: sampleProducts[0], quantity: 1),
          CartLine(product: sampleProducts[1], quantity: 1),
        ],
        total: 135500,
        status: 'Chờ xác nhận',
      ),
    ];
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onOpenProduct,
    required this.store,
  });

  final StoreOrder order;
  final ValueChanged<Product> onOpenProduct;
  final StoreController store;

  /// dựng thẻ đơn hàng, cho phép mua lại hoặc mở thông tin chi tiết.
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday =
        order.createdAt.year == now.year &&
        order.createdAt.month == now.month &&
        order.createdAt.day == now.day;
    final dateText = isToday
        ? 'Hôm nay'
        : '${order.createdAt.day.toString().padLeft(2, '0')}/${order.createdAt.month.toString().padLeft(2, '0')}/${order.createdAt.year}';
    final statusColor = switch (order.status) {
      'Đang giao' => const Color(0xFF3078D4),
      'Đã giao' => AppColors.blue700,
      'Đã hủy' => const Color(0xFFE45858),
      _ => AppColors.orange,
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${order.id}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        dateText,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    child: Text(
                      order.status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 54,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: order.lines.length,
                separatorBuilder: (_, _) => const SizedBox(width: 7),
                itemBuilder: (context, index) {
                  final line = order.lines[index];
                  return InkWell(
                    onTap: () => onOpenProduct(line.product),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 54,
                        height: 54,
                        child: ProductImage(imageUrl: line.product.imageUrl),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 20),
            Row(
              children: [
                Text(
                  '${order.lines.length} sản phẩm',
                  style: const TextStyle(color: AppColors.muted, fontSize: 9),
                ),
                const Spacer(),
                const Text(
                  'Tổng: ',
                  style: TextStyle(color: AppColors.muted, fontSize: 9),
                ),
                Text(
                  formatVnd(order.total),
                  style: const TextStyle(
                    color: AppColors.blue800,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      for (final line in order.lines) {
                        store.addToCart(line.product, quantity: line.quantity);
                      }
                      showSmartMartNotice(
                        context,
                        message: 'Đã thêm lại sản phẩm vào giỏ hàng',
                        icon: Icons.shopping_bag_outlined,
                      );
                    },
                    child: const Text('Mua lại'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showOrderDetails(context, order),
                    child: const Text('Xem chi tiết'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// mở bảng chi tiết gồm trạng thái, sản phẩm và tổng tiền đơn hàng.
  void _showOrderDetails(BuildContext context, StoreOrder order) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Đơn hàng #${order.id}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Trạng thái: ${order.status}',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 10),
              ...order.lines.map(
                (line) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${line.product.name} × ${line.quantity}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      Text(
                        formatVnd(line.total),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Tổng: ${formatVnd(order.total)}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// hiển thị thông tin tài khoản và các thao tác dành cho người mua.
class AccountScreen extends StatelessWidget {
  const AccountScreen({
    required this.onLogin,
    required this.onOpenMenu,
    required this.onOpenOrders,
    required this.onLogout,
    required this.userName,
    required this.userEmail,
    required this.isLoggedIn,
    super.key,
  });

  final VoidCallback onLogin;
  final VoidCallback onOpenMenu;
  final VoidCallback onOpenOrders;
  final VoidCallback onLogout;
  final String userName;
  final String userEmail;
  final bool isLoggedIn;

  /// dựng trang tài khoản với thông tin thành viên và các mục thao tác.
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 17),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF1F7FF), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  SmartMartLogo(onTap: onOpenMenu),
                  const Spacer(),
                  const Icon(Icons.notifications_none_rounded),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.blue700,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'K',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          userEmail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppColors.muted, fontSize: 8),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Thành viên Bạc',
                          style: TextStyle(
                            color: Color(0xFFB16A1E),
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.muted),
                ],
              ),
              const SizedBox(height: 17),
              Container(
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.blue900,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ProfileMetric(value: '1.280', label: 'Điểm SSM4'),
                    VerticalDivider(
                      color: Colors.white24,
                      indent: 15,
                      endIndent: 15,
                    ),
                    _ProfileMetric(value: '12', label: 'Yêu thích'),
                    VerticalDivider(
                      color: Colors.white24,
                      indent: 15,
                      endIndent: 15,
                    ),
                    _ProfileMetric(value: '8', label: 'Đơn hàng'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            children: [
              Card(
                color: const Color(0xFFFFF6E6),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFE2AD),
                    child: Icon(
                      Icons.workspace_premium_outlined,
                      color: Color(0xFFAD6C1B),
                    ),
                  ),
                  title: const Text(
                    'Nâng hạng thành viên Vàng',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Chỉ còn 720 điểm nữa',
                    style: TextStyle(color: AppColors.muted, fontSize: 8),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _AccountMenuItem(
                      icon: Icons.person_outline,
                      title: 'Thông tin cá nhân',
                      subtitle: 'Cập nhật hồ sơ của bạn',
                      onTap: () {},
                    ),
                    _AccountMenuItem(
                      icon: Icons.location_on_outlined,
                      title: 'Địa chỉ giao hàng',
                      subtitle: '2 địa chỉ đã lưu',
                      onTap: () {},
                    ),
                    _AccountMenuItem(
                      icon: Icons.receipt_long_outlined,
                      title: 'Đơn hàng của tôi',
                      subtitle: 'Theo dõi và quản lý đơn hàng',
                      onTap: onOpenOrders,
                    ),
                    _AccountMenuItem(
                      icon: Icons.credit_card_outlined,
                      title: 'Phương thức thanh toán',
                      subtitle: 'Thẻ và ví điện tử',
                      onTap: () {},
                    ),
                    _AccountMenuItem(
                      icon: Icons.favorite_border,
                      title: 'Sản phẩm yêu thích',
                      subtitle: '12 sản phẩm',
                      onTap: () {},
                    ),
                    _AccountMenuItem(
                      icon: Icons.notifications_none,
                      title: 'Thông báo',
                      subtitle: '3 thông báo mới',
                      onTap: () {},
                    ),
                    _AccountMenuItem(
                      icon: Icons.settings_outlined,
                      title: 'Cài đặt',
                      subtitle: 'Ngôn ngữ, bảo mật',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isLoggedIn ? onLogout : onLogin,
                  icon: Icon(
                    isLoggedIn ? Icons.logout : Icons.login,
                    color: isLoggedIn
                        ? const Color(0xFFE45858)
                        : AppColors.blue700,
                  ),
                  label: const Text(
                    'Đăng xuất / Đăng nhập, đăng ký',
                    style: TextStyle(color: Color(0xFFE45858)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFF3D9D9)),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'SSM4 v1.0.0 · Giao diện mẫu',
                style: TextStyle(color: Color(0xFFA8B0AC), fontSize: 8),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({required this.value, required this.label});

  final String value;
  final String label;

  /// hiển thị một chỉ số tài khoản cùng nhãn mô tả.
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFB9D7C4), fontSize: 7),
        ),
      ],
    );
  }
}

class _AccountMenuItem extends StatelessWidget {
  const _AccountMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// dựng một mục có biểu tượng, tiêu đề và mô tả trong menu tài khoản.
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.blue50,
        child: Icon(icon, color: AppColors.blue700, size: 19),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.muted, fontSize: 8),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Color(0xFFA6AFA9),
        size: 19,
      ),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 1),
    );
  }
}

/// chào mừng người dùng sau khi hoàn tất bước đăng nhập mẫu.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({required this.userName, this.onFinished, super.key});

  final String userName;
  final VoidCallback? onFinished;

  /// dựng hiệu ứng chào mừng toàn màn hình và gọi tiếp khi kết thúc.
  @override
  Widget build(BuildContext context) {
    return BrandAnimationScreen(
      title: 'Chào mừng bạn quay lại',
      subtitle: 'Rất vui được gặp lại, $userName',
      riderEnters: true,
      onFinished: onFinished ?? () => Navigator.of(context).pop(),
    );
  }
}

/// hiển thị hiệu ứng thương hiệu dùng lúc khởi động ứng dụng.
class BrandAnimationScreen extends StatefulWidget {
  const BrandAnimationScreen({
    required this.title,
    required this.subtitle,
    this.riderEnters = true,
    this.onFinished,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool riderEnters;
  final VoidCallback? onFinished;

  /// tạo trạng thái điều khiển chuyển động của hình tài xế.
  @override
  State<BrandAnimationScreen> createState() => _BrandAnimationScreenState();
}

class _BrandAnimationScreenState extends State<BrandAnimationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _riderPosition;
  late final Animation<double> _riderOpacity;
  late final Animation<double> _textOpacity;

  /// bắt đầu bộ điều khiển hoạt ảnh khi màn hình được tạo.
  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: Duration(milliseconds: widget.riderEnters ? 2800 : 1700),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) widget.onFinished?.call();
        });
    _riderPosition = widget.riderEnters
        ? TweenSequence<Offset>([
            TweenSequenceItem(
              tween: Tween(
                begin: const Offset(-1.2, 0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOutCubic)),
              weight: 36,
            ),
            TweenSequenceItem(tween: ConstantTween(Offset.zero), weight: 32),
            TweenSequenceItem(
              tween: Tween(
                begin: Offset.zero,
                end: const Offset(1.5, 0),
              ).chain(CurveTween(curve: Curves.easeInCubic)),
              weight: 32,
            ),
          ]).animate(_controller)
        : TweenSequence<Offset>([
            TweenSequenceItem(tween: ConstantTween(Offset.zero), weight: 48),
            TweenSequenceItem(
              tween: Tween(
                begin: Offset.zero,
                end: const Offset(1.5, 0),
              ).chain(CurveTween(curve: Curves.easeInCubic)),
              weight: 52,
            ),
          ]).animate(_controller);
    _riderOpacity = widget.riderEnters
        ? TweenSequence<double>([
            TweenSequenceItem(
              tween: Tween(
                begin: 0.0,
                end: 1.0,
              ).chain(CurveTween(curve: Curves.easeOut)),
              weight: 22,
            ),
            TweenSequenceItem(tween: ConstantTween(1.0), weight: 56),
            TweenSequenceItem(
              tween: Tween(
                begin: 1.0,
                end: 0.0,
              ).chain(CurveTween(curve: Curves.easeIn)),
              weight: 22,
            ),
          ]).animate(_controller)
        : TweenSequence<double>([
            TweenSequenceItem(tween: ConstantTween(1.0), weight: 48),
            TweenSequenceItem(
              tween: Tween(
                begin: 1.0,
                end: 0.0,
              ).chain(CurveTween(curve: Curves.easeIn)),
              weight: 52,
            ),
          ]).animate(_controller);
    _textOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 34,
      ),
      TweenSequenceItem(tween: ConstantTween(1), weight: 34),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 32,
      ),
    ]).animate(_controller);
    _controller.forward();
  }

  /// giải phóng bộ điều khiển hoạt ảnh khi màn hình đóng.
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// dựng hình tài xế cùng hiệu ứng vào và rời khỏi màn hình.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FD),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 290,
              height: 290,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.blue100.withValues(alpha: 0.65),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _riderOpacity,
                    child: SlideTransition(
                      position: _riderPosition,
                      child: FractionallySizedBox(
                        widthFactor: 0.94,
                        child: AspectRatio(
                          aspectRatio: 1150 / 800,
                          child: Image.asset(
                            'assets/images/ssm4_delivery_rider.png',
                            key: const ValueKey('delivery-rider'),
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FadeTransition(
                    opacity: _textOpacity,
                    child: Column(
                      children: [
                        if (widget.title.isNotEmpty) ...[
                          Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.blue900,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        const _Ssm4Wordmark(),
                        const SizedBox(height: 9),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 26),
                          child: Text(
                            widget.subtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
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

class _Ssm4Wordmark extends StatelessWidget {
  const _Ssm4Wordmark();

  /// dựng chữ nhận diện ssm4 với màu riêng cho phần số.
  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'SSM',
            style: TextStyle(color: AppColors.blue700),
          ),
          TextSpan(
            text: '4',
            style: TextStyle(color: AppColors.blue600),
          ),
        ],
      ),
      style: TextStyle(
        fontSize: 42,
        fontWeight: FontWeight.w900,
        letterSpacing: -2,
        height: 1,
      ),
    );
  }
}
