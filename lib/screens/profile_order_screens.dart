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

  /// ghép các đơn đã mua với một số đơn mẫu để minh họa lịch sử.
  List<StoreOrder> _demoOrders(StoreController store) {
    final now = DateTime.now();
    final examples = <StoreOrder>[
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
    return [...store.orders, ...examples];
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

/// thu thập thông tin tài khoản và trả kết quả về nơi mở màn hình.
class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.onComplete, super.key});

  final void Function(String name, String email, String role) onComplete;

  /// tạo trạng thái biểu mẫu đăng nhập và đăng ký.
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'CUSTOMER';
  bool _passwordVisible = false;
  bool _rememberMe = true;
  bool _isRegistering = false;
  bool _isSubmitting = false;

  /// giải phóng bộ điều khiển văn bản khi màn hình đăng nhập đóng.
  @override
  void dispose() {
    _nameController.dispose();
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// dựng biểu mẫu đăng nhập hoặc đăng ký tùy chế độ hiện tại.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _LoginHero(
              isRegistering: _isRegistering,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.12),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: Column(
                        key: ValueKey(_isRegistering),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isRegistering
                                ? 'Tạo tài khoản'
                                : 'Chào mừng trở lại!',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _isRegistering
                                ? 'Đăng ký để mua sắm tiện lợi cùng SSM4'
                                : 'Đăng nhập để tiếp tục mua sắm cùng SSM4',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeInOutCubic,
                      child: _isRegistering
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _LoginFieldLabel(
                                  label: 'Tên của bạn',
                                  child: TextFormField(
                                    controller: _nameController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    decoration: const InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.person_outline_rounded,
                                      ),
                                      hintText: 'Nhập tên hiển thị',
                                    ),
                                    validator: (value) =>
                                        _isRegistering &&
                                            (value == null ||
                                                value.trim().isEmpty)
                                        ? 'Vui lòng nhập tên hiển thị'
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                    _LoginFieldLabel(
                      label: 'Email hoặc số điện thoại',
                      child: TextFormField(
                        controller: _accountController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                          hintText: 'Nhập email hoặc số điện thoại',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Vui lòng nhập email hoặc số điện thoại'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _LoginFieldLabel(
                      label: 'Mật khẩu',
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: !_passwordVisible,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          hintText: _isRegistering
                              ? 'Tạo mật khẩu (ít nhất 6 ký tự)'
                              : 'Nhập mật khẩu',
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => _passwordVisible = !_passwordVisible,
                            ),
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                        validator: (value) => value == null || value.length < 6
                            ? 'Mật khẩu cần có ít nhất 6 ký tự'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _LoginFieldLabel(
                      label: 'Vai trò tài khoản (Phân quyền UI)',
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedRole,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'CUSTOMER',
                            child: Text('🛒 Khách hàng (Mua sắm)'),
                          ),
                          DropdownMenuItem(
                            value: 'SALES_STAFF',
                            child: Text('🏷️ Nhân viên Bán hàng (POS & Kệ)'),
                          ),
                          DropdownMenuItem(
                            value: 'WAREHOUSE_STAFF',
                            child: Text('📦 Nhân viên Kho (Nhập & Tồn kho)'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedRole = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) =>
                              setState(() => _rememberMe = value ?? false),
                          visualDensity: VisualDensity.compact,
                        ),
                        const Text(
                          'Ghi nhớ tôi',
                          style: TextStyle(fontSize: 8),
                        ),
                        const Spacer(),
                        if (!_isRegistering)
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Quên mật khẩu?',
                              style: TextStyle(fontSize: 8),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _LoginSubmitButton(
                      isRegistering: _isRegistering,
                      isLoading: _isSubmitting,
                      onPressed: _submit,
                    ),
                    if (!_isRegistering)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 19),
                        child: Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'Hoặc đăng nhập với',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 8,
                                ),
                              ),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                      ),
                    if (!_isRegistering)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.g_mobiledata, size: 22),
                              label: const Text('Google'),
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.facebook, size: 19),
                              label: const Text('Facebook'),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () =>
                          setState(() => _isRegistering = !_isRegistering),
                      child: Text(
                        _isRegistering
                            ? 'Đã có tài khoản? Đăng nhập'
                            : 'Chưa có tài khoản? Đăng ký ngay',
                        style: const TextStyle(
                          color: AppColors.blue700,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Đây là luồng giao diện mẫu; đăng nhập thực tế cần kết nối dịch vụ xác thực.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, fontSize: 8),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// kiểm tra biểu mẫu rồi gửi tên và email về màn hình gọi.
  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    final account = _accountController.text.trim();
    final name = _isRegistering
        ? _nameController.text.trim()
        : account.split('@').first;
    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    widget.onComplete(name, account, _selectedRole);
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero({required this.isRegistering, required this.onBack});

  final bool isRegistering;
  final VoidCallback onBack;

  /// dựng phần đầu đăng nhập có logo, hình tài xế và tiêu đề động.
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 370,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.blue900, AppColors.blue700, AppColors.blue600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -64,
            top: 37,
            child: Container(
              width: 236,
              height: 236,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: -31,
            top: 72,
            width: MediaQuery.sizeOf(context).width * 0.68,
            height: 260,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.92, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, scale, child) => Transform.scale(
                scale: scale,
                alignment: Alignment.centerRight,
                child: child,
              ),
              child: Image.asset(
                'assets/images/ssm4_delivery_rider.png',
                key: const ValueKey('login-rider-art'),
                fit: BoxFit.contain,
                alignment: Alignment.centerRight,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          Positioned(
            left: 17,
            right: 17,
            top: 14,
            child: Row(
              children: [
                Image.asset(
                  'assets/images/logo_ssms4.png',
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    'ShoppongSmartMart4',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Quay lại',
                  onPressed: onBack,
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.14),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 19),
                ),
              ],
            ),
          ),
          Positioned(
            left: 21,
            bottom: 27,
            width: MediaQuery.sizeOf(context).width * 0.53,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Column(
                key: ValueKey(isRegistering),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRegistering
                        ? 'Gia nhập gia đình SSM4'
                        : 'Tươi ngon, chọn thật dễ',
                    maxLines: 2,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Thực phẩm chất lượng, giao đến tận nhà.',
                    style: TextStyle(
                      color: Color(0xFFD6E8FF),
                      fontSize: 11,
                      height: 1.3,
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

class _LoginFieldLabel extends StatelessWidget {
  const _LoginFieldLabel({required this.label, required this.child});

  final String label;
  final Widget child;

  /// đặt nhãn phía trên trường nhập liệu để biểu mẫu dễ đọc hơn.
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _LoginSubmitButton extends StatelessWidget {
  const _LoginSubmitButton({
    required this.isRegistering,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isRegistering;
  final bool isLoading;
  final VoidCallback onPressed;

  /// tạo nút gửi biểu mẫu và hiện vòng tải khi đang xử lý.
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(17),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.blue900, AppColors.blue600],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
              color: AppColors.blue700.withValues(alpha: 0.24),
              blurRadius: 15,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          child: SizedBox(
            height: 54,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: isLoading
                    ? const SizedBox.square(
                        key: ValueKey('login-loading'),
                        dimension: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isRegistering ? 'Tạo tài khoản' : 'Đăng nhập',
                        key: ValueKey(isRegistering),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
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
