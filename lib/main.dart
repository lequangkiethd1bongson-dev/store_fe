import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/network/api_client.dart';
import 'services/auth_service.dart';

import 'data/sample_data.dart';
import 'models/store_models.dart';
import 'screens/cart_checkout_screens.dart';
import 'screens/catalog_screens.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_order_screens.dart';
import 'screens/staff_screens.dart';
import 'state/staff_controller.dart';
import 'state/store_controller.dart';
import 'theme/app_theme.dart';

/// Khởi chạy ứng dụng SSM4 và khởi tạo Supabase Auth.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://aaelclxxsknskpeqasfj.supabase.co',
  );
  const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_fGGwRPSnIamIZrUqSLtHuQ_eLJ8sonf',
  );

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: publishableKey,
  );

  final auth = Supabase.instance.client.auth;
  ApiClient.authToken = auth.currentSession?.accessToken;

  // Luôn đồng bộ access token với phiên Supabase hiện tại, kể cả khi token được làm mới.
  auth.onAuthStateChange.listen((state) {
    ApiClient.authToken = state.session?.accessToken;
  });

  runApp(const SmartMartApp());
}

/// tạo cấu hình ứng dụng và chọn màn hình đầu tiên cần hiển thị.
class SmartMartApp extends StatefulWidget {
  const SmartMartApp({super.key});

  /// tạo đối tượng quản lý trạng thái gốc của ứng dụng.
  /// liên kết cấu hình ứng dụng với lớp lưu trạng thái tương ứng.
  @override
  State<SmartMartApp> createState() => _SmartMartAppState();
}

class _SmartMartAppState extends State<SmartMartApp> {
  late final StoreController _store;
  late final StaffController _staffController;
  bool _showStartupAnimation = true;
  bool _isLoggedIn = false;
  bool _showLoginWelcome = false;
  String _userName = '';
  String _userEmail = '';
  String _userRole = 'CUSTOMER';


  @override
  void initState() {
    super.initState();
    _store = StoreController(
      products: sampleProducts,
      initialCart: const {'milk': 1, 'apple': 2, 'eggs': 1},
    );
    _staffController = StaffController(products: sampleProducts);

    _store.addListener(() {
      _staffController.updateProducts(_store.products);
    });

    // Nạp dữ liệu sản phẩm và đơn hàng trực tiếp từ backend khi khởi động app
    _store.loadProducts();
    _store.loadOrders();
    _staffController.loadFromApi();
  }

  /// giải phóng tài nguyên của các bộ quản lý khi ứng dụng bị gỡ khỏi cây giao diện.
  @override
  void dispose() {
    _store.dispose();
    _staffController.dispose();
    super.dispose();
  }

  /// chọn màn hình khởi động, đăng nhập, chào mừng hoặc khu mua sắm theo đúng vai trò.
  @override
  Widget build(BuildContext context) {
    Widget homeWidget;
    if (_showStartupAnimation) {
      homeWidget = BrandAnimationScreen(
        title: '',
        subtitle: 'Đang chuẩn bị trải nghiệm mua sắm của bạn',
        onFinished: _finishStartup,
      );
    } else if (!_isLoggedIn) {
      homeWidget = LoginScreen(onComplete: _completeInitialLogin);
    } else if (_showLoginWelcome) {
      homeWidget = WelcomeScreen(
        userName: _userName,
        onFinished: () {
          if (mounted) setState(() => _showLoginWelcome = false);
        },
      );
    } else if (_userRole == 'STORE_MANAGER' || _userRole == 'SALES_STAFF') {
      homeWidget = StoreStaffWorkspace(
        controller: _staffController,
        staffName: _userName,
        userRole: _userRole,
        onExit: () => _updateSession(null, null),
      );
    } else if (_userRole == 'WAREHOUSE_STAFF' || _userRole == 'WAREHOUSE_MANAGER') {
      homeWidget = WarehouseStaffWorkspace(
        controller: _staffController,
        staffName: _userName,
        onExit: () => _updateSession(null, null),
      );
    } else if (_userRole == 'ADMIN') {
      // Không điều hướng Admin vào giao diện khách hàng.
      // Thay màn hình thông báo này bằng widget quản trị thực tế khi đã có.
      homeWidget = _AdminRouteGuardScreen(
        userName: _userName,
        userEmail: _userEmail,
        onLogout: () => _updateSession(null, null),
      );
    } else {
      homeWidget = RootShell(
        store: _store,
        staffController: _staffController,
        initialUserName: _userName,
        initialUserEmail: _userEmail,
        initialUserRole: _userRole,
        onAuthChanged: _updateSession,
      );
    }

    return MaterialApp(
      title: 'SSM4',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      scrollBehavior: const _FixedScrollBehavior(),
      home: AnimatedBuilder(
        animation: _store,
        builder: (context, _) => homeWidget,
      ),
    );
  }

  /// Khôi phục phiên từ Supabase; SharedPreferences chỉ lưu thông tin hiển thị,
  /// không được dùng làm bằng chứng xác thực.
  Future<void> _finishStartup() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        await _clearSavedSession(signOut: false);
      } else {
        ApiClient.authToken = session.accessToken;
        final profile = await _fetchVerifiedProfile();
        await _saveVerifiedProfile(profile);
      }
    } catch (error) {
      debugPrint('Khôi phục phiên Supabase thất bại: $error');
      await _clearSavedSession(signOut: true);
    } finally {
      if (mounted) {
        setState(() {
          _showStartupAnimation = false;
        });
      }
    }
  }

  /// Chỉ lấy tên/email/role từ hồ sơ Java sau khi access token Supabase được xác minh.
  Future<Map<String, String>> _fetchVerifiedProfile() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null || session.accessToken.isEmpty) {
      throw const FormatException('Không có phiên Supabase đang đăng nhập.');
    }

    ApiClient.authToken = session.accessToken;
    final authService = AuthService();
    try {
      final profile = await authService.getMe();
      final name = (profile['name'] ?? profile['fullName'] ?? '').toString().trim();
      final email = (profile['email'] ?? '').toString().trim();
      final role = (profile['role'] ?? '').toString().trim().toUpperCase();

      const allowedRoles = <String>{
        'STORE_MANAGER',
        'SALES_STAFF',
        'WAREHOUSE_STAFF',
        'WAREHOUSE_MANAGER',
        'ADMIN',
      };

      if (name.isEmpty || email.isEmpty || role.isEmpty) {
        throw const FormatException('Hồ sơ nhân viên chưa đầy đủ.');
      }
      if (!allowedRoles.contains(role)) {
        throw const FormatException(
          'Tài khoản chưa được Admin cấp vai trò hợp lệ.',
        );
      }

      return <String, String>{
        'name': name,
        'email': email,
        'role': role,
      };
    } finally {
      authService.dispose();
    }
  }

  /// Lưu profile đã được Java xác nhận. Không lưu mật khẩu hoặc token vào SharedPreferences.
  Future<void> _saveVerifiedProfile(Map<String, String> profile) async {
    final preferences = await SharedPreferences.getInstance();
    final name = profile['name']!;
    final email = profile['email']!;
    final role = profile['role']!;

    await preferences.setBool('session.loggedIn', true);
    await preferences.setString('session.userName', name);
    await preferences.setString('session.userEmail', email);
    await preferences.setString('session.userRole', role);

    if (!mounted) return;
    setState(() {
      _isLoggedIn = true;
      _userName = name;
      _userEmail = email;
      _userRole = role;
    });
  }

  /// Khi màn hình đăng nhập đầu tiên gọi callback, xác minh profile lần nữa ở lớp gốc.
  /// Điều này chặn callback cũ/local đi tiếp nếu không có session thật.
  Future<void> _completeInitialLogin(
      String name,
      String email,
      String role,
      ) async {
    if (Supabase.instance.client.auth.currentSession == null) {
      ApiClient.authToken = null;
      debugPrint('Bỏ qua callback đăng nhập vì không có Supabase session.');
      return;
    }

    try {
      final profile = await _fetchVerifiedProfile();
      await _saveVerifiedProfile(profile);
      if (mounted) {
        setState(() => _showLoginWelcome = true);
      }
    } catch (error) {
      debugPrint('Không xác minh được hồ sơ sau đăng nhập: $error');
      await _clearSavedSession(signOut: true);
    }
  }

  /// Cập nhật phiên từ callback chung. Role truyền từ UI không được tin cậy;
  /// dữ liệu thật luôn được đọc lại từ Java/employee profile.
  Future<void> _updateSession(
      String? name,
      String? email, [
        String? role,
      ]) async {
    if (name == null || email == null) {
      await _clearSavedSession(signOut: true);
      return;
    }

    if (Supabase.instance.client.auth.currentSession == null) {
      ApiClient.authToken = null;
      debugPrint('Từ chối tạo phiên UI vì Supabase session không tồn tại.');
      return;
    }

    try {
      final profile = await _fetchVerifiedProfile();
      await _saveVerifiedProfile(profile);
    } catch (error) {
      debugPrint('Không thể cập nhật phiên đăng nhập: $error');
      await _clearSavedSession(signOut: true);
    }
  }

  /// Xóa cache UI và token; signOut=true sẽ kết thúc phiên Supabase.
  Future<void> _clearSavedSession({required bool signOut}) async {
    ApiClient.authToken = null;
    if (signOut) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (error) {
        debugPrint('Không thể signOut từ Supabase: $error');
      }
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('session.loggedIn');
    await preferences.remove('session.userName');
    await preferences.remove('session.userEmail');
    await preferences.remove('session.userRole');

    if (!mounted) return;
    setState(() {
      _isLoggedIn = false;
      _userName = '';
      _userEmail = '';
      _userRole = 'CUSTOMER';
      _showLoginWelcome = false;
    });
  }

}

/// Guard tạm cho role ADMIN: không để tài khoản quản trị rơi vào giao diện khách hàng.
/// Thay bằng màn hình quản trị/cấp quyền thực tế khi widget Admin đã có trong dự án.
class _AdminRouteGuardScreen extends StatelessWidget {
  const _AdminRouteGuardScreen({
    required this.userName,
    required this.userEmail,
    required this.onLogout,
  });

  final String userName;
  final String userEmail;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Quản trị viên SSM4'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.admin_panel_settings_outlined,
                      size: 56,
                      color: AppColors.blue700,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Xin chào, $userName',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      userEmail,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Đăng nhập Admin đã được xác minh. Tuy nhiên, main.dart '
                          'chưa được nối với màn hình quản trị/cấp quyền thực tế. '
                          'Tài khoản Admin được giữ ở màn hình này thay vì bị '
                          'đưa vào giao diện khách hàng.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Đăng xuất'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// giữ dữ liệu và điều hướng chính của khu vực mua sắm (Giao diện Khách hàng - Customer UI).
class RootShell extends StatefulWidget {
  const RootShell({
    required this.store,
    required this.staffController,
    required this.initialUserName,
    required this.initialUserEmail,
    this.initialUserRole = 'CUSTOMER',
    required this.onAuthChanged,
    super.key,
  });

  final StoreController store;
  final StaffController staffController;
  final String initialUserName;
  final String initialUserEmail;
  final String initialUserRole;
  final Future<void> Function(String?, String?, [String?]) onAuthChanged;

  /// tạo trạng thái điều hướng chính cho khu vực mua sắm.
  /// liên kết thanh điều hướng với trạng thái của nó.
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _selectedTab = 0;
  late String _userName;
  late String _userEmail;

  /// nạp tên và email hiện tại khi tạo thanh điều hướng gốc.
  @override
  void initState() {
    super.initState();
    _userName = widget.initialUserName;
    _userEmail = widget.initialUserEmail;
  }

  /// mở danh sách sản phẩm, có thể lọc theo nhóm hàng được chọn.
  void _openProducts({String? category}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductListScreen(
          store: widget.store,
          category: category ?? 'Rau củ quả',
          onOpenProduct: _openProduct,
          onOpenCart: _openCart,
        ),
      ),
    );
  }

  /// mở trang chi tiết cho sản phẩm người dùng vừa chọn.
  void _openProduct(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailScreen(
          store: widget.store,
          product: product,
          onCheckout: _openCheckout,
          onOpenCart: _openCart,
          onOpenProduct: _openProduct,
        ),
      ),
    );
  }

  /// mở giỏ hàng và nối thao tác thanh toán.
  void _openCart() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            CartScreen(store: widget.store, onCheckout: _openCheckout),
      ),
    );
  }

  /// mở màn hình nhập thông tin và xác nhận đơn hàng.
  void _openCheckout() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            CheckoutScreen(store: widget.store, onOrderPlaced: _openSuccess),
      ),
    );
  }

  /// hiển thị kết quả đặt hàng và thay thế các trang mua hàng trước đó.
  void _openSuccess(StoreOrder order) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => OrderSuccessScreen(
          order: order,
          onContinueShopping: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
            setState(() => _selectedTab = 0);
          },
          onViewOrders: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
            setState(() => _selectedTab = 3);
          },
        ),
      ),
          (route) => route.isFirst,
    );
  }

  /// dựng các trang mua sắm và thanh điều hướng chính.
  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final pages = <Widget>[
      HomeScreen(
        store: store,
        onOpenProducts: (category) => _openProducts(category: category),
        onOpenCategories: () => setState(() => _selectedTab = 1),
        onOpenProduct: _openProduct,
        onOpenMenu: _showSideMenu,
        onOpenCart: _openCart,
      ),
      CategoryScreen(
        categories: store.categories,
        onSelectCategory: (name) => _openProducts(category: name),
      ),
      CartScreen(store: store, onCheckout: _openCheckout),
      OrdersScreen(store: store, onOpenProduct: _openProduct),
      AccountScreen(
        onLogin: _openLogin,
        onOpenMenu: _showSideMenu,
        onLogout: _logOut,
        onOpenOrders: () => setState(() => _selectedTab = 3),
        userName: _userName,
        userEmail: _userEmail,
        isLoggedIn: _userEmail != 'Đăng nhập để đồng bộ đơn hàng',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 640;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWide ? 480 : double.infinity,
            ),
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: _selectedTab == 0
                    ? Colors.transparent
                    : Colors.white,
                statusBarIconBrightness: _selectedTab == 0
                    ? Brightness.light
                    : Brightness.dark,
                statusBarBrightness: _selectedTab == 0
                    ? Brightness.dark
                    : Brightness.light,
              ),
              child: Scaffold(
                backgroundColor: AppColors.canvas,
                extendBody: true,
                body: SafeArea(
                  top: _selectedTab != 0,
                  bottom: false,
                  child: RefreshIndicator(
                    color: AppColors.blue700,
                    onRefresh: widget.store.refreshDemoData,
                    child: IndexedStack(index: _selectedTab, children: pages),
                  ),
                ),
                bottomNavigationBar: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: _GlassBottomNavigation(
                    currentIndex: _selectedTab,
                    cartCount: store.cartCount,
                    onTap: (index) {
                      if (index == null) {
                        _showQrScanner();
                      } else {
                        setState(() => _selectedTab = index);
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// mở màn hình đăng nhập và cập nhật thông tin khi người dùng hoàn tất.
  Future<void> _openLogin() async {
    final credentials = await Navigator.of(context).push<(String, String, String)>(
      PageRouteBuilder<(String, String, String)>(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(
          onComplete: (name, email, role) =>
              Navigator.of(context).pop((name, email, role)),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                Tween<Offset>(
                  begin: const Offset(0, 0.035),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              ),
            ),
      ),
    );
    if (credentials == null || !mounted) return;

    await widget.onAuthChanged(credentials.$1, credentials.$2, credentials.$3);
    if (!mounted) return;
    setState(() {
      _userName = credentials.$1;
      _userEmail = credentials.$2;
      _selectedTab = 0;
    });
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 650),
        pageBuilder: (context, animation, secondaryAnimation) =>
            WelcomeScreen(userName: credentials.$1),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  /// xóa phiên hiện tại rồi đưa tên hiển thị về trạng thái khách.
  Future<void> _logOut() async {
    await widget.onAuthChanged(null, null);
    if (!mounted) return;
    setState(() {
      _userName = 'Khách hàng';
      _userEmail = 'Đăng nhập để đồng bộ đơn hàng';
    });
  }

  /// hiển thị thông báo chờ tích hợp chức năng quét qr bằng camera.
  Future<void> _showQrScanner() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.qr_code_scanner_rounded,
          size: 42,
          color: AppColors.blue700,
        ),
        title: const Text('Quét mã QR'),
        content: const Text(
          'Chức năng mở camera để quét mã QR sẽ được kết nối sau.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  /// mở menu tài khoản và xử lý yêu cầu đăng nhập.
  Future<void> _showSideMenu() async {
    var shouldOpenLogin = false;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Đóng menu',
      barrierColor: AppColors.blue900.withValues(alpha: 0.32),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) => Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: 2 / 3,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: _SideMenu(
              userName: _userName,
              userEmail: _userEmail,
              isLoggedIn: _userEmail != 'Đăng nhập để đồng bộ đơn hàng',
              onSelect: (index) {
                Navigator.of(context).pop();
                setState(() => _selectedTab = index);
              },
              onLogin: () {
                shouldOpenLogin = true;
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) =>
          SlideTransition(
            position:
            Tween<Offset>(
              begin: const Offset(-1, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          ),
    );
    if (shouldOpenLogin && mounted) _openLogin();
  }
}

class _FixedScrollBehavior extends MaterialScrollBehavior {
  const _FixedScrollBehavior();

  /// dùng kiểu cuộn không nảy để giữ bố cục màn hình ổn định.
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();

  /// bỏ hiệu ứng trang trí ở mép khi danh sách cuộn quá giới hạn.
  @override
  Widget buildOverscrollIndicator(
      BuildContext context,
      Widget child,
      ScrollableDetails details,
      ) => child;
}

class _CartNavIcon extends StatelessWidget {
  const _CartNavIcon({required this.count});

  final int count;

  /// vẽ biểu tượng giỏ hàng kèm số lượng sản phẩm hiện có.
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.shopping_cart_outlined),
        if (count > 0)
          Positioned(
            right: -10,
            top: -7,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: const BoxDecoration(
                color: AppColors.orange,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GlassBottomNavigation extends StatelessWidget {
  const _GlassBottomNavigation({
    required this.currentIndex,
    required this.cartCount,
    required this.onTap,
  });

  final int currentIndex;
  final int cartCount;
  final ValueChanged<int?> onTap;

  static const _items = <(IconData, IconData, String, int?)>[
    (Icons.home_outlined, Icons.home_rounded, 'Trang chủ', 0),
    (Icons.grid_view_rounded, Icons.grid_view_rounded, 'Danh mục', 1),
    (
    Icons.qr_code_scanner_rounded,
    Icons.qr_code_scanner_rounded,
    'Quét mã QR',
    null,
    ),
    (Icons.shopping_cart_outlined, Icons.shopping_cart_rounded, 'Giỏ hàng', 2),
    (Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Đơn hàng', 3),
  ];

  /// dựng thanh điều hướng kính mờ và làm nổi bật tab đang chọn.
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      key: const ValueKey('glass-bottom-navigation'),
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.92)),
            boxShadow: [
              BoxShadow(
                color: AppColors.blue900.withValues(alpha: 0.14),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final selected = item.$4 == currentIndex;
              final icon = selected ? item.$2 : item.$1;
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: selected,
                  label: item.$3,
                  child: InkWell(
                    key: ValueKey('main-tab-$index'),
                    onTap: () => onTap(item.$4),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.blue700.withValues(alpha: 0.16)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 27,
                              child: Center(
                                child: item.$4 == null
                                    ? Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: AppColors.blue700,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.blue900
                                            .withValues(alpha: 0.24),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.qr_code_scanner_rounded,
                                    size: 19,
                                    color: Colors.white,
                                  ),
                                )
                                    : item.$4 == 2
                                    ? _CartNavIcon(count: cartCount)
                                    : Icon(
                                  icon,
                                  size: 23,
                                  color: selected
                                      ? AppColors.blue700
                                      : AppColors.blue800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                              style: TextStyle(
                                color: selected
                                    ? AppColors.blue700
                                    : AppColors.blue900,
                                fontSize: 9,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                              child: Text(item.$3, maxLines: 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _SideMenu extends StatelessWidget {
  const _SideMenu({
    required this.userName,
    required this.userEmail,
    required this.isLoggedIn,
    required this.onSelect,
    required this.onLogin,
  });

  final String userName;
  final String userEmail;
  final bool isLoggedIn;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogin;

  /// dựng menu tài khoản trượt bên cạnh với các lối tắt trong ứng dụng.
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 28, 18, 22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.blue900, AppColors.blue700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'K',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFD6E8FF),
                      fontSize: 11,
                    ),
                  ),
                  if (isLoggedIn) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Thành viên SSM4',
                      style: TextStyle(
                        color: Color(0xFFFFD58A),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            _SideMenuItem(
              icon: Icons.home_outlined,
              title: 'Trang chủ',
              onTap: () => onSelect(0),
            ),
            _SideMenuItem(
              icon: Icons.grid_view_rounded,
              title: 'Danh mục sản phẩm',
              onTap: () => onSelect(1),
            ),
            _SideMenuItem(
              icon: Icons.shopping_cart_outlined,
              title: 'Giỏ hàng',
              onTap: () => onSelect(2),
            ),
            _SideMenuItem(
              icon: Icons.receipt_long_outlined,
              title: 'Đơn hàng của tôi',
              onTap: () => onSelect(3),
            ),
            _SideMenuItem(
              icon: Icons.person_outline_rounded,
              title: 'Tài khoản',
              onTap: () => onSelect(4),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: onLogin,
                icon: Icon(
                  isLoggedIn ? Icons.switch_account : Icons.login,
                  size: 18,
                ),
                label: Text(
                  isLoggedIn ? 'Đổi tài khoản' : 'Đăng nhập / Đăng ký',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideMenuItem extends StatelessWidget {
  const _SideMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  /// dựng một hàng lựa chọn có biểu tượng, nhãn và trạng thái được chọn.
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.blue700),
      title: Text(title, style: const TextStyle(fontSize: 13)),
      onTap: onTap,
    );
  }
}