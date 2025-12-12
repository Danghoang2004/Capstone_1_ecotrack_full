import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/data/models/report_model.dart';
import 'api_client.dart';

class ReportService {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  late final ApiClient apiClient = ApiClient(storage: storage);
  Future<List<Report>> fetchMyReports() async {
    final response = await apiClient.get("/api/user/reports");
    if (response.statusCode == 200) {
      // Decode JSON sang List
      final List<dynamic> data = apiClient.decodeUtf8Json(response);
      return data.map((json) => Report.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  // --- API CHO ADMIN: Lấy TẤT CẢ báo cáo ---
  Future<List<Report>> fetchAllReports() async {
    final response = await apiClient.get("/api/admin/reports");

    if (response.statusCode == 200) {
      final List<dynamic> data = apiClient.decodeUtf8Json(response);
      return data.map((json) => Report.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  // ---  API CHO ADMIN: Cập nhật trạng thái ---
  Future<bool> updateReportStatus(int reportId, String newStatus) async {
    try {
      final response = await apiClient.put(
        "/api/admin/reports/$reportId/status",
        {"status": newStatus},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> uploadReport({
    required String title,
    required String description,
    required String latitude,
    required String longitude,
    required String trashCategory,
    required String status,
    required String imagePath,
  }) async {
    try {
      final response = await apiClient.postMultipart(
        "/api/user/reports/upload",
        {
          "title": title,
          "description": description,
          "latitude": latitude,
          "longitude": longitude,
          "category": trashCategory,
          "status": status,
        },
        {"image": imagePath},
      );

      if (response.statusCode == 200) return true;

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getReports() async {
    final response = await apiClient.get("/api/reports");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return [];
  }

  // Get report theo id
  Future<Map<String, dynamic>?> getReportById(int id) async {
    final response = await apiClient.get("/api/reports/$id");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }
}
