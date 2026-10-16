import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';

class ApiClient {
  final http.Client _client = http.Client();

  Future<http.Response> get(String path) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');

    return _client
        .get(uri)
        .timeout(const Duration(seconds: 15));
  }

  void dispose() {
    _client.close();
  }
}