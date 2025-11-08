import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String baseUrl = 'http://192.168.1.89:8080';

  // Đăng nhập
  Future<bool> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      if (token != null) {
        await _storage.write(key: 'jwt_token', value: token);
        return true;
      }
    }
    print('Login failed: ${response.statusCode}');
    return false;
  }

  // Đăng ký
  Future<bool> register(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/register');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'username': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];

      if (token != null) {
        await _storage.write(key: 'jwt_token', value: token);
        print('Register successful, token saved.');
        return true;
      }
    }

    print('Register failed: ${response.statusCode}');
    return false;
  }

  //  Đăng xuất
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  // Lấy token hiện tại
  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }
}
