import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/presentation/user_app/notification/notification_screen.dart';

class NotificationService {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  late final ApiClient apiClient = ApiClient(storage: storage);

  Future<List<NotificationItem>> getAll() async {
    final res = await apiClient.get("/api/notifications");

    if (res.statusCode == 200) {
      final body = apiClient.decodeUtf8Json(res) as List<dynamic>;
      return body
          .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception("Lỗi tải thông báo: ${res.statusCode}");
  }

  Future<void> markAsRead(String id) async {
    final res = await apiClient.post("/api/notifications/$id/read", {});
    if (res.statusCode != 200) {
      throw Exception("Không đánh dấu đã đọc được");
    }
  }
}
