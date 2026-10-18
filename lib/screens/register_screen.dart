import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Màn hình đăng ký tài khoản riêng biệt (tách rời hoàn toàn khỏi màn hình đăng nhập).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({required this.onComplete, super.key});

  final void Function(String name, String email, String role) onComplete;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _passwordVisible = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _accountController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final account = _accountController.text.trim();
    final password = _passwordController.text;
    final role = _determineRole(account);

    setState(() => _isSubmitting = true);

    String finalName = name;
    String finalEmail = account;
    String finalRole = role;

    try {
      final authService = AuthService();
      final res = await authService.register(
        name: name,
        account: account,
        password: password,
      );
      if (res['user'] is Map) {
        final user = res['user'] as Map;
        finalName = user['name']?.toString() ?? finalName;
        finalEmail = user['email']?.toString() ?? user['account']?.toString() ?? finalEmail;
        finalRole = user['role']?.toString() ?? finalRole;
      }
    } catch (e) {
      debugPrint('Đăng ký qua backend API không thành công (dùng tài khoản local): $e');
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    widget.onComplete(finalName, finalEmail, finalRole);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 280,
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
                    left: 16,
                    top: 16,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    ),
                  ),
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add_rounded, size: 56, color: Colors.white),
                        SizedBox(height: 12),
                        Text(
                          'Tạo tài khoản SSM4',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Đăng ký thành viên mới cùng hệ thống',
                          style: TextStyle(color: Color(0xFFD6E8FF), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Thông tin đăng ký',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _RegisterFieldLabel(
                      label: 'Tên hiển thị của bạn',
                      child: TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person_outline_rounded),
                          hintText: 'Nhập họ và tên',
                        ),
                        validator: (val) =>
                            val == null || val.trim().isEmpty ? 'Vui lòng nhập tên hiển thị' : null,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _RegisterFieldLabel(
                      label: 'Email hoặc số điện thoại',
                      child: TextFormField(
                        controller: _accountController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                          hintText: 'Nhập email hoặc số điện thoại',
                        ),
                        validator: (val) =>
                            val == null || val.trim().isEmpty ? 'Vui lòng nhập email hoặc SĐT' : null,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _RegisterFieldLabel(
                      label: 'Mật khẩu',
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: !_passwordVisible,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          hintText: 'Ít nhất 6 ký tự',
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                            icon: Icon(_passwordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          ),
                        ),
                        validator: (val) =>
                            val == null || val.length < 6 ? 'Mật khẩu cần ít nhất 6 ký tự' : null,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _RegisterFieldLabel(
                      label: 'Xác nhận mật khẩu',
                      child: TextFormField(
                        controller: _confirmController,
                        obscureText: !_passwordVisible,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.lock_reset_rounded),
                          hintText: 'Nhập lại mật khẩu',
                        ),
                        validator: (val) =>
                            val != _passwordController.text ? 'Mật khẩu xác nhận không khớp' : null,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'ĐĂNG KÝ TÀI KHOẢN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Đã có tài khoản? Đăng nhập ngay',
                        style: TextStyle(
                          color: AppColors.blue700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

class _RegisterFieldLabel extends StatelessWidget {
  const _RegisterFieldLabel({required this.label, required this.child});

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
