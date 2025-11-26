import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

class ReportService {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  late final ApiClient apiClient = ApiClient(storage: storage);

  //  Upload report với ảnh
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
      print("Upload error: $e");
      return false;
    }
  }

  // Get danh sách report
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
