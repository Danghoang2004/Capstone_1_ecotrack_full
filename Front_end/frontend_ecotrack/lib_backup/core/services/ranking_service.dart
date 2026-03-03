import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';

class RankingService {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  late final ApiClient apiClient = ApiClient(storage: storage);

  Future<List<Map<String, dynamic>>> getIndividualRankings() async {
    final response = await apiClient.get("/api/ranking/individual");

    // Nếu có 401, ApiClient đã xử lý (gọi SessionService.handleSessionExpired())
    // Không cần throw exception nữa, chỉ return empty list
    // Dialog session expired sẽ được hiển thị bởi SessionService
    if (response.statusCode == 401) {
      return [];
    }

    if (response.statusCode != 200) {
      throw Exception("Lỗi server: ${response.statusCode}");
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return List<Map<String, dynamic>>.from(body);
  }

  Future<List<Map<String, dynamic>>> getGroupRankings() async {
    final response = await apiClient.get("/api/ranking/group");

    // Nếu có 401, ApiClient đã xử lý (gọi SessionService.handleSessionExpired())
    // Không cần throw exception nữa, chỉ return empty list
    // Dialog session expired sẽ được hiển thị bởi SessionService
    if (response.statusCode == 401) {
      return [];
    }

    if (response.statusCode != 200) {
      throw Exception("Lỗi server: ${response.statusCode}");
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return List<Map<String, dynamic>>.from(body);
  }
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = 'Unauthorized']);
  @override
  String toString() => 'UnauthorizedException: $message';
}
