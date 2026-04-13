import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._internal();
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String baseUrl = dotenv.env['API_BASE_URL']!;

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

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '798523892228-hihng8k1s63khd4pcsp54fpgpqrdd60m.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );
  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return {'success': false, 'message': 'Huỷ đăng nhập Google'};
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;

      if (idToken == null) {
        return {'success': false, 'message': 'Không lấy được Google token'};
      }

      final url = Uri.parse('$baseUrl/api/auth/google');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'idToken': idToken}),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && data['accessToken'] != null) {
        // Lưu JWT
        await _storage.write(key: 'jwt_token', value: data['accessToken']);

        return {'success': true};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Đăng nhập Google thất bại',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi Google Login: $e'};
    }
  }

  Future<void> logoutGoogle() async {
    try {
      await _googleSignIn.signOut();
      if (!kIsWeb) {
        await _googleSignIn.disconnect();
      }
    } catch (e) {
      print('Lỗi khi ngắt kết nối Google: $e');
    }

    await logout();
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

  // --- 4. Quên mật khẩu ---
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final url = Uri.parse('$baseUrl/api/auth/reset-password/request');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? data['error'] ?? 'Gửi email thất bại',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Không thể kết nối server'};
    }
  }

  Future<Map<String, dynamic>> confirmResetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    final url = Uri.parse('$baseUrl/api/auth/reset-password/confirm');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        }),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message':
              data['message'] ?? data['error'] ?? 'Xác nhận OTP thất bại',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Không thể kết nối server'};
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
        return false;
      }
    }
    return false;
  }

  // Thêm hàm kiểm tra Partner
  Future<bool> isPartner() async {
    final rolesJson = await _storage.read(key: 'user_roles');
    if (rolesJson != null) {
      try {
        final roles = jsonDecode(rolesJson);
        // Kiểm tra xem danh sách roles có chứa ROLE_PARTNER hay không
        return roles.contains("ROLE_PARTNER");
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  Future<bool> isEnvironment() async {
    final rolesJson = await _storage.read(key: 'user_roles');
    if (rolesJson != null) {
      try {
        final roles = jsonDecode(rolesJson);
        return roles.contains("ROLE_ENVIRONMENT");
      } catch (e) {
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
        return [];
      }
    }
    return [];
  }

  // Lấy username đã lưu sau khi login
  Future<String?> getUsername() async {
    return await _storage.read(key: 'username');
  }

  // Lấy email đã lưu sau khi login
  Future<String?> getEmail() async {
    return await _storage.read(key: 'email');
  }
}
