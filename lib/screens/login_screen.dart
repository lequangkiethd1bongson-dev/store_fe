import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart';

/// Màn hình đăng nhập riêng biệt (tự động nhận diện role từ tài khoản, không còn chọn role thủ công).
class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.onComplete, super.key});

  final void Function(String name, String email, String role) onComplete;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _rememberMe = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _determineRole(String email) {
    final clean = email.toLowerCase();
    if (clean.contains('warehouse') || clean.contains('kho')) {
      return 'WAREHOUSE_STAFF';
    }
    if (clean.contains('sales') || clean.contains('banhang') || clean.contains('staff') || clean.contains('nhanvien')) {
      return 'SALES_STAFF';
    }
    return 'CUSTOMER';
  }


  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) {
      return;
    }

    final account = _accountController.text.trim();
    final password = _passwordController.text;
    final inputName = account.split('@').first;

    setState(() => _isSubmitting = true);

    try {
      // 1. Đăng nhập Firebase và xác thực với Java Backend.
      final authService = AuthService();
      final res = await authService.login(
        account: account,
        password: password,
      );

      // 2. Đọc dữ liệu người dùng.
      // Hỗ trợ cả JSON dạng {"user": {...}}
      // và JSON dạng {"role": "kho", ...}
      final dynamic rawUser =
      res['user'] is Map ? res['user'] : res;

      if (rawUser is! Map) {
        throw Exception('Dữ liệu người dùng không hợp lệ.');
      }

      // 3. Lấy role do Backend trả về.
      final role = rawUser['role']
          ?.toString()
          .trim()
          .toLowerCase();

      debugPrint('ROLE RECEIVED FROM BACKEND: $role');

      if (role != 'kho' && role != 'sale') {
        throw Exception(
          'Backend không trả về role hợp lệ: $role',
        );
      }

      // 4. Lấy thông tin nhân viên.
      final name = rawUser['name'] ??
          rawUser['userName'] ??
          rawUser['user_name'] ??
          rawUser['username'];

      final email = rawUser['email'] ??
          rawUser['account'];

      final finalName =
      name?.toString().trim().isNotEmpty == true
          ? name.toString().trim()
          : inputName;

      final finalEmail =
      email?.toString().trim().isNotEmpty == true
          ? email.toString().trim()
          : account;

      // 5. Chuyển thông tin đã xác thực cho màn hình cha.
      final appRole = role == 'kho'
          ? 'WAREHOUSE_STAFF'
          : 'SALES_STAFF';

      debugPrint('ROLE FROM BACKEND: $role');
      debugPrint('ROLE SENT TO APP: $appRole');

      widget.onComplete(finalName, finalEmail, appRole);
    } catch (e) {
      debugPrint('Đăng nhập thất bại: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đăng nhập thất bại: $e'),
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
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _LoginHero(
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Chào mừng trở lại!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Đăng nhập để tiếp tục trải nghiệm cùng SSM4',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 24),
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
                    const SizedBox(height: 16),
                    _LoginFieldLabel(
                      label: 'Mật khẩu',
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: !_passwordVisible,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          hintText: 'Nhập mật khẩu',
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
                    const SizedBox(height: 6),
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
                          style: TextStyle(fontSize: 10),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Quên mật khẩu?',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _LoginSubmitButton(
                      isLoading: _isSubmitting,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 19),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'Hoặc đăng nhập với',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.g_mobiledata, size: 22),
                            label: const Text('Google'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.facebook, size: 19),
                            label: const Text('Facebook'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => RegisterScreen(
                              onComplete: widget.onComplete,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Chưa có tài khoản? Đăng ký ngay',
                        style: TextStyle(
                          color: AppColors.blue700,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Hệ thống tự động nhận diện phân quyền từ tài khoản (VD: chứa sales/kho).',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, fontSize: 9),
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
}

class _LoginHero extends StatelessWidget {
  const _LoginHero({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
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
            child: Image.asset(
              'assets/images/ssm4_delivery_rider.png',
              fit: BoxFit.contain,
              alignment: Alignment.centerRight,
              filterQuality: FilterQuality.high,
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
                    'ShoppingSmartMart4',
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
                  ),
                  icon: const Icon(Icons.close_rounded, size: 19),
                ),
              ],
            ),
          ),
          const Positioned(
            left: 21,
            bottom: 27,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tươi ngon, chọn thật dễ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 7),
                Text(
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
        ],
      ),
    );
  }
}

class _LoginFieldLabel extends StatelessWidget {
  const _LoginFieldLabel({required this.label, required this.child});

  final String label;
  final Widget child;

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
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

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
                        dimension: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Đăng nhập',
                        style: TextStyle(
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
