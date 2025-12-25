import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';
import 'package:http/http.dart' as http;

class ReportService {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  late final ApiClient apiClient = ApiClient(storage: storage);

  //  Upload report với ảnh
  // Trong file report_service.dart

  Future<Map<String, dynamic>?> uploadReport({
    required String title,
    required String description,
    required String latitude,
    required String longitude,
    required String trashCategory,
    required String status,
    required String imagePath,
  }) async {
    try {
      final streamedResponse = await apiClient.postMultipart(
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

      final response = await http.Response.fromStream(streamedResponse);

      // Giải mã JSON bất kể statusCode là bao nhiêu
      final Map<String, dynamic> responseData = apiClient.decodeUtf8Json(response);

      // Thêm statusCode vào map để xử lý ở UI nếu cần
      responseData['statusCode'] = response.statusCode;

      return responseData;
    } catch (e) {
      print("Error upload: $e");
      return {"success": false, "message": "Không thể kết nối máy chủ: $e"};
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
