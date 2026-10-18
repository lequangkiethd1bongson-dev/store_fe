import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

/// Dịch vụ kết nối API xác thực tài khoản (Đăng nhập / Đăng ký).
class AuthService {
  AuthService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// POST /auth/login — Đăng nhập hệ thống.
  Future<Map<String, dynamic>> login({
    required String account,
    required String password,
  }) async {
    final data = await _apiClient.post(
      ApiConstants.login,
      body: {'account': account, 'password': password},
    );
    if (data is Map<String, dynamic>) {
      final token = data['token']?.toString();
      if (token != null && token.isNotEmpty) {
        ApiClient.authToken = token;
      }
      return data;
    }
    return {};
  }

  /// POST /auth/register — Đăng ký tài khoản mới.
  Future<Map<String, dynamic>> register({
    required String name,
    required String account,
    required String password,
  }) async {
    final data = await _apiClient.post(
      ApiConstants.register,
      body: {'name': name, 'account': account, 'password': password},
    );
    if (data is Map<String, dynamic>) {
      final token = data['token']?.toString();
      if (token != null && token.isNotEmpty) {
        ApiClient.authToken = token;
      }
      return data;
    }
    return {};
  }

  /// GET /users/me — Lấy thông tin người dùng đang đăng nhập.
  Future<Map<String, dynamic>> getMe() async {
    final data = await _apiClient.get(ApiConstants.me);
    if (data is Map<String, dynamic>) return data;
    return {};
  }
}
