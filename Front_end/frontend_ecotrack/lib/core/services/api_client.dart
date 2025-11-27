import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend_ecotrack/core/services/session_service.dart';

class ApiClient {
  final String baseUrl = dotenv.env['API_BASE_URL']!;
  final FlutterSecureStorage storage;

  ApiClient({required this.storage});

  // Helper method để check và handle 401
  Future<http.Response> _handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      // Bất kỳ 401 nào cũng được xem là session expired
      // (có thể do token hết hạn, user bị disable, hoặc thông tin thay đổi)
      await SessionService.handleSessionExpired();
    }
    return response;
  }

  Future<Map<String, String>> _headers({
    bool json = true,
  }) async {
    final token = await storage.read(key: 'jwt_token');

    final map = <String, String>{};

    if (json) {
      map['Content-Type'] = 'application/json; charset=utf-8';
    }

    map['Accept'] = 'application/json; charset=utf-8';
    // Note: 'Accept-Charset' is a forbidden header in browsers, removed to prevent errors

    if (token != null) {
      map['Authorization'] = 'Bearer $token';
    }

    return map;
  }

  Future<http.Response> get(String path) async {
    final headers = await _headers(json: false);
    final response = await http.get(Uri.parse('$baseUrl$path'), headers: headers);
    return _handleResponse(response);
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final headers = await _headers(json: true);
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<http.Response> put(String path, Map<String, dynamic> body) async {
    final headers = await _headers(json: true);
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<http.Response> delete(String path) async {
    final headers = await _headers(json: false);
    final response = await http.delete(Uri.parse('$baseUrl$path'), headers: headers);
    return _handleResponse(response);
  }

  Future<http.StreamedResponse> postMultipart(
    String path,
    Map<String, String> fields,
    Map<String, String> files,
  ) async {
    final token = await storage.read(key: 'jwt_token');

    var request = http.MultipartRequest("POST", Uri.parse('$baseUrl$path'));

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    fields.forEach((key, value) => request.fields[key] = value);

    for (var file in files.entries) {
      request.files.add(
        await http.MultipartFile.fromPath(file.key, file.value),
      );
    }

    return await request.send();
  }

  dynamic decodeUtf8Json(http.Response response) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  }
}
