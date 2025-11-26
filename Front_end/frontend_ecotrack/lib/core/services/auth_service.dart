import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  // IP backend của bạn
  final String baseUrl = 'http://192.168.1.89:8080';

  // --- 1. Đăng ký ---
  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String username,
  ) async {
    final url = Uri.parse('$baseUrl/api/auth/register');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        }, // Thêm charset
        body: jsonEncode({
          'email': email,
          'password': password,
          'username': username,
        }),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        // Backend trả về Token và Roles ngay khi đăng ký thành công (theo bản sửa trước)
        if (data['token'] != null) {
          await _saveUserData(data);
        }
        return {'success': true, 'message': 'Đăng ký thành công'};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? data['error'] ?? 'Đăng ký thất bại',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // --- 2. Xác thực OTP ---
  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    final url = Uri.parse('$baseUrl/api/auth/verify');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({"email": email, "code": otp}),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        final token = data['token'];
        if (token != null) {
          await _storage.write(key: 'jwt_token', value: token);
          // OTP xong thường là User mới, gán tạm quyền User
          await _storage.write(
            key: 'user_roles',
            value: jsonEncode(["ROLE_USER"]),
          );
          return {'success': true};
        }
      }
      return {
        'success': false,
        'message': data['error'] ?? 'Mã xác thực không đúng',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // --- 3. Đăng nhập (QUAN TRỌNG) ---
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        await _saveUserData(data);
        return {'success': true};
      } else {
        // Trả về lỗi cụ thể từ Backend (ví dụ: chưa verify email, sai pass)
        return {
          'success': false,
          'message': data['error'] ?? 'Đăng nhập thất bại',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Không thể kết nối máy chủ ($e)'};
    }
  }

  // --- Hàm phụ: Lưu dữ liệu User vào máy ---
  Future<void> _saveUserData(Map<String, dynamic> data) async {
    final token = data['token'];
    final roles = data['roles'];
    final username = data['username'];
    final email = data['email'];

    if (token != null) await _storage.write(key: 'jwt_token', value: token);
    if (roles != null)
      await _storage.write(key: 'user_roles', value: jsonEncode(roles));
    if (username != null)
      await _storage.write(key: 'username', value: username);
    if (email != null) await _storage.write(key: 'email', value: email);
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  // Thêm hàm này vào class AuthService
  Future<bool> isAdmin() async {
    final rolesJson = await _storage.read(key: 'user_roles');
    if (rolesJson != null) {
      try {
        final roles = jsonDecode(rolesJson);
        // Kiểm tra xem danh sách roles có chứa ROLE_ADMIN hay không
        return roles.contains("ROLE_ADMIN");
      } catch (e) {
        print("Lỗi decode roles: $e");
        return false;
      }
    }
    return false;
  }

  Future<bool> isPartner() async {
    final rolesJson = await _storage.read(key: 'user_roles');
    if (rolesJson != null) {
      try {
        final roles = jsonDecode(rolesJson);
        // Kiểm tra xem danh sách roles có chứa ROLE_PARTNER hay không
        return roles.contains("ROLE_PARTNER");
      } catch (e) {
        print("Lỗi decode roles: $e");
        return false;
      }
    }
    return false;
  }

  // Thêm hàm lấy Roles
  Future<List<String>> getRoles() async {
    final rolesJson = await _storage.read(key: 'user_roles');
    if (rolesJson != null) {
      try {
        final roles = jsonDecode(rolesJson) as List<dynamic>;
        return roles.cast<String>();
      } catch (e) {
        print("Lỗi decode roles: $e");
        return [];
      }
    }
    return [];
  }
}
