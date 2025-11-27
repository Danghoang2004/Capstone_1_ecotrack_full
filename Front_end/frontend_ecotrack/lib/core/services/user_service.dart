// lib/core/services/user_service.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/data/models/ProfileView.dart';

class UserService {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  late final ApiClient apiClient = ApiClient(storage: storage);

  Future<ProfileView> getProfileView() async {
    final response = await apiClient.get("/api/user/profile");

    // Nếu có 401, ApiClient đã xử lý (gọi SessionService.handleSessionExpired())
    // Không cần throw exception nữa, chỉ throw để ProfileScreen có thể handle
    // Nhưng dialog đã được hiển thị bởi SessionService
    if (response.statusCode == 401) {
      throw UnauthorizedException("Token expired");
    }

    if (response.statusCode != 200) {
      throw Exception("Lỗi server: ${response.statusCode}");
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return ProfileView.fromJson(body);
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final response = await apiClient.get("/api/user/getAllUser");

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

  Future<void> updateUser(int userId, Map<String, dynamic> data) async {
    final response = await apiClient.put("/api/user/$userId", data);

    // Nếu có 401, ApiClient đã xử lý (gọi SessionService.handleSessionExpired())
    // Không cần throw exception nữa, chỉ return
    // Dialog session expired sẽ được hiển thị bởi SessionService
    if (response.statusCode == 401) {
      return;
    }

    if (response.statusCode != 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final error = body['error'] ?? 'Lỗi server: ${response.statusCode}';
      throw Exception(error);
    }
  }

  Future<void> deleteUser(int userId) async {
    final response = await apiClient.delete("/api/user/$userId");

    // Nếu có 401, ApiClient đã xử lý (gọi SessionService.handleSessionExpired())
    // Không cần throw exception nữa, chỉ return
    // Dialog session expired sẽ được hiển thị bởi SessionService
    if (response.statusCode == 401) {
      return;
    }

    if (response.statusCode != 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final error = body['error'] ?? 'Lỗi server: ${response.statusCode}';
      throw Exception(error);
    }
  }

  Future<void> deleteUsers(List<int> userIds) async {
    final response = await apiClient.post("/api/user/bulk/delete", {
      'userIds': userIds,
    });

    // Nếu có 401, ApiClient đã xử lý (gọi SessionService.handleSessionExpired())
    // Không cần throw exception nữa, chỉ return
    // Dialog session expired sẽ được hiển thị bởi SessionService
    if (response.statusCode == 401) {
      return;
    }

    if (response.statusCode != 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final error = body['error'] ?? 'Lỗi server: ${response.statusCode}';
      throw Exception(error);
    }
  }
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = 'Unauthorized']);
  @override
  String toString() => 'UnauthorizedException: $message';
}
