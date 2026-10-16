import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';

/// lỗi thống nhất khi gọi api, giúp giao diện hiện thông báo dễ hiểu.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => statusCode == null
      ? 'ApiException: $message'
      : 'ApiException($statusCode): $message';
}

/// BƯỚC 2 — gửi yêu cầu http tới backend và trả về json đã giải mã.
///
/// mọi service chỉ cần gọi `get`, `post`, `put`, `patch`, `delete` với
/// đường dẫn trong [ApiConstants]; lớp này lo phần ghép url, header,
/// thời gian chờ, giải mã utf-8 và chuyển lỗi http thành [ApiException].
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// token đăng nhập, được gắn vào header `Authorization` nếu có.
  static String? authToken;

  /// gửi yêu cầu GET, có thể kèm tham số truy vấn như `?category=...`.
  Future<dynamic> get(String path, {Map<String, String?>? query}) =>
      _send('GET', path, query: query);

  /// gửi yêu cầu POST với body json.
  Future<dynamic> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  /// gửi yêu cầu PUT với body json.
  Future<dynamic> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);

  /// gửi yêu cầu PATCH với body json.
  Future<dynamic> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  /// gửi yêu cầu DELETE.
  Future<dynamic> delete(String path) => _send('DELETE', path);

  /// giải phóng kết nối khi không dùng nữa.
  void dispose() => _client.close();

  /// ghép url, gửi yêu cầu và xử lý kết quả chung cho mọi phương thức.
  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String?>? query,
    Object? body,
  }) async {
    final uri = _buildUri(path, query);
    final request = http.Request(method, uri)
      ..headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=utf-8',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      });
    if (body != null) request.body = jsonEncode(body);

    final http.Response response;
    try {
      final streamed = await _client.send(request).timeout(ApiConstants.timeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const ApiException('Máy chủ phản hồi quá lâu, vui lòng thử lại.');
    } on http.ClientException {
      // http 1.x gói cả lỗi socket (sai ip, backend chưa chạy) vào đây.
      throw const ApiException('Không kết nối được máy chủ.');
    }

    // giải mã theo utf-8 để không lỗi tiếng việt có dấu.
    final text = utf8.decode(response.bodyBytes);
    final dynamic data = text.isEmpty ? null : _tryDecode(text);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }
    final message = data is Map && data['message'] != null
        ? data['message'].toString()
        : 'Lỗi máy chủ (HTTP ${response.statusCode}).';
    throw ApiException(message, statusCode: response.statusCode);
  }

  /// ghép baseUrl với đường dẫn và bỏ các tham số rỗng.
  Uri _buildUri(String path, Map<String, String?>? query) {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final params = <String, String>{
      for (final entry in (query ?? const <String, String?>{}).entries)
        if (entry.value != null && entry.value!.trim().isNotEmpty)
          entry.key: entry.value!.trim(),
    };
    return params.isEmpty ? uri : uri.replace(queryParameters: params);
  }

  /// thử đọc json, nếu backend trả chuỗi thường thì giữ nguyên chuỗi.
  dynamic _tryDecode(String text) {
    try {
      return jsonDecode(text);
    } on FormatException {
      return text;
    }
  }
}