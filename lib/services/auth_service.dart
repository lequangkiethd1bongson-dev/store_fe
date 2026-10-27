import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

/// Supabase Auth handles credentials; Java verifies the access token and returns
/// the employee profile/role. Registration never grants an application session.
class AuthService {
  AuthService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(),
        _ownsClient = apiClient == null;

  final ApiClient _apiClient;
  final bool _ownsClient;

  void dispose() {
    if (_ownsClient) _apiClient.dispose();
  }

  Future<Map<String, dynamic>> login({
    required String account,
    required String password,
  }) async {
    final email = account.trim();
    if (!_looksLikeEmail(email)) {
      throw const ApiException('Vui lòng đăng nhập bằng email.');
    }

    final AuthResponse authResponse;
    try {
      authResponse = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final session = authResponse.session;
      debugPrint('SUPABASE LOGIN: ${session != null}');
      debugPrint('SUPABASE USER: ${authResponse.user?.id}');
      debugPrint('ACCESS TOKEN EXISTS: ${session?.accessToken.isNotEmpty}');
    } on AuthException catch (e) {
      throw ApiException(_friendlyAuthMessage(e));
    } catch (e, stackTrace) {
      debugPrint('LOGIN ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }

    final session = authResponse.session;
    if (session == null || session.accessToken.isEmpty) {
      throw const ApiException(
        'Không nhận được phiên đăng nhập. Hãy kiểm tra xác nhận email.',
      );
    }

    debugPrint('BACKEND URL: ${ApiConstants.baseUrl}');
    debugPrint('CALLING BACKEND LOGIN...');
    ApiClient.authToken = session.accessToken;

    try {
      final profile = await getMe();
      return {'user': profile};
    } on ApiException catch (e) {
      await _clearSession();
      if (e.statusCode == 403) {
        throw const ApiException(
          'Tài khoản chưa được Admin kích hoạt/cấp quyền. Vui lòng liên hệ Admin.',
          statusCode: 403,
        );
      }
      if (e.statusCode == 401) {
        throw const ApiException(
          'Phiên đăng nhập không hợp lệ hoặc đã hết hạn. Vui lòng đăng nhập lại.',
          statusCode: 401,
        );
      }
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('LOGIN ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
      await _clearSession();
      rethrow;
    }
  }

  /// Creates the Supabase Auth user. SQL trigger creates employees with
  /// is_active=false. We deliberately do not call onComplete/login here.
  Future<Map<String, dynamic>> register({
    required String name,
    required String account,
    required String password,
  }) async {
    final email = account.trim();
    if (!_looksLikeEmail(email)) {
      throw const ApiException('Vui lòng nhập địa chỉ email hợp lệ.');
    }
    if (name.trim().isEmpty) {
      throw const ApiException('Vui lòng nhập họ tên.');
    }
    if (password.length < 6) {
      throw const ApiException('Mật khẩu cần ít nhất 6 ký tự.');
    }

    // Avoid retaining a previous session when registering a different account.
    await _clearSession();

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name.trim()},
      );

      final user = response.user;
      if (user == null) {
        throw const ApiException('Supabase không trả về tài khoản vừa tạo.');
      }

      // If email confirmation is disabled, Supabase may also return a session.
      // Log it out locally: a newly registered employee must still await Admin.
      if (response.session != null) {
        await Supabase.instance.client.auth.signOut();
      }
      ApiClient.authToken = null;

      return {
        'registered': true,
        'emailConfirmationRequired': response.session == null,
        'user': {
          'id': user.id,
          'name': name.trim(),
          'email': user.email ?? email,
        },
      };
    } on AuthException catch (e) {
      ApiClient.authToken = null;
      throw ApiException(_friendlyAuthMessage(e));
    }
  }

  /// GET /api/auth/me. The Java API rejects employees which are inactive or
  /// have no employee profile. Role returned to UI is mapped from DB role only.
  Future<Map<String, dynamic>> getMe() async {
    final data = await _apiClient.get(ApiConstants.me);
    if (data is! Map) {
      throw const ApiException('Dữ liệu hồ sơ từ backend không hợp lệ.');
    }

    final profile = Map<String, dynamic>.from(data);
    final dbRole = (profile['role'] ?? profile['databaseRole'] ?? '')
        .toString()
        .toLowerCase();

    profile['databaseRole'] = dbRole;
    profile['role'] = _appRoleForDatabaseRole(dbRole);
    profile['name'] = profile['name']?.toString() ??
        profile['fullName']?.toString() ?? '';
    profile['email'] = profile['email']?.toString() ?? '';
    return profile;
  }

  Future<void> logout() => _clearSession();

  Future<void> _clearSession() async {
    ApiClient.authToken = null;
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      // Clear the local API token even if remote sign-out cannot complete.
    }
  }

  static bool _looksLikeEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  static String _appRoleForDatabaseRole(String role) {
    switch (role.toLowerCase()) {
      case 'store_manager':
        return 'STORE_MANAGER';
      case 'sales':
      case 'sales_staff':
        return 'SALES_STAFF';
      case 'kho_manager':
        return 'WAREHOUSE_MANAGER';
      case 'kho':
      case 'warehouse_staff':
        return 'WAREHOUSE_STAFF';
      case 'admin':
        return 'ADMIN';
      default:
        throw const ApiException(
          'Vai trò tài khoản chưa hợp lệ. Vui lòng liên hệ Admin.',
        );
    }
  }

  static String _friendlyAuthMessage(AuthException error) {
    switch (error.code) {
      case 'invalid_credentials':
        return 'Email hoặc mật khẩu không đúng.';
      case 'email_not_confirmed':
        return 'Vui lòng xác nhận email trước khi đăng nhập.';
      case 'user_already_exists':
      case 'email_exists':
        return 'Email này đã được đăng ký.';
      case 'weak_password':
        return 'Mật khẩu quá yếu; hãy dùng ít nhất 6 ký tự.';
      case 'invalid_email':
        return 'Địa chỉ email không hợp lệ.';
      default:
        return error.message.isNotEmpty
            ? error.message
            : 'Xác thực không thành công. Vui lòng thử lại.';
    }
  }
}
