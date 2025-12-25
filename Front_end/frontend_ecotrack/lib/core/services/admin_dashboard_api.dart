import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:frontend_ecotrack/data/models/dashboard_models.dart';
import 'package:frontend_ecotrack/core/services/auth_service.dart';

class AdminDashboardApi {
  final String baseUrl = dotenv.env['API_BASE_URL']!;
  final AuthService _authService = AuthService();

  Future<DashboardSummary> fetchDashboard() async {
    // Lấy token đã lưu sau khi login
    final token = await _authService.getToken();

    if (token == null) {
      // Chưa login hoặc mất token
      throw Exception("Chưa đăng nhập hoặc token không tồn tại");
    }

    final res = await http.get(
      Uri.parse("$baseUrl/api/admin/dashboard"),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      return DashboardSummary.fromJson(data);
    } else if (res.statusCode == 403) {
      // Có token nhưng BE nói không đủ quyền
      throw Exception("Không có quyền truy cập dashboard (403)");
    } else {
      throw Exception("Lỗi load dashboard: ${res.statusCode}");
    }
  }
}
