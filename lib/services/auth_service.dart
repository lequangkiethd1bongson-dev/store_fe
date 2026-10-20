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
    // Bước 1: Thử đăng nhập qua Firebase Authentication trước
    String? idToken;
    try {
      final credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: account.trim(),
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser != null) {
        idToken = await firebaseUser.getIdToken();
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth failed (${e.code}): ${e.message}');
      if (e.code == 'wrong-password' ||
          e.code == 'user-not-found' ||
          e.code == 'invalid-credential') {
        throw ApiException(
          e.code == 'user-not-found'
              ? 'Tài khoản chưa được đăng ký.'
              : 'Mật khẩu hoặc tài khoản không đúng.',
        );
      }
      throw ApiException(
        'Lỗi xác thực Firebase (${e.code}): ${e.message ?? 'Không kết nối được Firebase.'}',
      );
    } catch (e) {
      debugPrint('Firebase Error: $e');
      throw ApiException('Không kết nối được dịch vụ xác thực Firebase ($e).');
    }

    if (idToken == null || idToken.isEmpty) {
      throw const ApiException('Không lấy được mã idToken từ Firebase.');
    }

    // Bước 2: Gọi Backend API truyền idToken đã lấy từ Firebase
    try {
      final data = await _apiClient.post(
        ApiConstants.login,
        body: {
          'idToken': idToken,
          'account': account.trim(),
          'password': password,
        },
      );
      if (data is Map) {
        ApiClient.authToken = idToken;
        return Map<String, dynamic>.from(data);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Không kết nối được máy chủ Backend ($e).');
    }

    throw const ApiException('Đăng nhập không thành công, vui lòng thử lại.');
  }

  /// POST /users/register — Đăng ký tài khoản mới.
  Future<Map<String, dynamic>> register({
    required String name,
    required String account,
    required String password,
  }) async {
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: account.trim(),
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser != null) {
        await firebaseUser.updateDisplayName(name);
        final idToken = await firebaseUser.getIdToken();
        final data = await _apiClient.post(
          ApiConstants.register,
          body: {
            'name': name,
            'account': account,
            'idToken': idToken,
          },
        );
        if (data is Map) {
          ApiClient.authToken = idToken;
          return Map<String, dynamic>.from(data);
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Lỗi đăng ký Firebase (${e.code}).';
      if (e.code == 'email-already-in-use') {
        message = 'Email này đã được đăng ký tài khoản.';
      } else if (e.code == 'weak-password') {
        message = 'Mật khẩu quá yếu (cần ít nhất 6 ký tự).';
      } else if (e.message != null && e.message!.isNotEmpty) {
        message = e.message!;
      }
      throw ApiException(message);
    } catch (_) {
      // Bỏ qua và gọi tiếp API backend nếu chưa hỗ trợ firebase
    }

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