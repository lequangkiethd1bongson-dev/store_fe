import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
    // Bước 1: Đăng nhập bằng Firebase Authentication.
    // account phải là email đã đăng ký trong Firebase Authentication.
    final credential =
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: account.trim(),
      password: password,
    );

    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw const ApiException(
        'Firebase không trả về thông tin người dùng.',
      );
    }

    // Bước 2: Lấy Firebase ID token.
    final idToken = await firebaseUser.getIdToken();

    if (idToken == null || idToken.isEmpty) {
      throw const ApiException(
        'Không lấy được Firebase ID token.',
      );
    }

    // Bước 3: Gửi token cho Java Backend xác minh.
    final data = await _apiClient.post(
      ApiConstants.login,
      body: {
        'idToken': idToken,
      },
    );
    debugPrint('LOGIN RESPONSE FROM BACKEND: $data');


    // Bước 4: Chỉ lưu token dùng cho các API tiếp theo
    // sau khi Backend xác minh và trả về thành công.
    if (data is Map) {
      ApiClient.authToken = idToken;
      return Map<String, dynamic>.from(data);
    }

    throw const ApiException(
      'Backend trả về dữ liệu người dùng không hợp lệ.',
    );
  }

  /// POST user/register — Đăng ký tài khoản mới.
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
