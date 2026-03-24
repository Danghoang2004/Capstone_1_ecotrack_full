import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/data/models/NotificationModelAdmin.dart';
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

  Future<List<NotificationModel>> getAdminNotifications() async {
    try {
      final response = await apiClient.get('/api/admin/notifications');

      if (response.statusCode == 200) {
        final List<dynamic> data =
            apiClient.decodeUtf8Json(response) as List<dynamic>;
        return data
            .map(
              (json) =>
                  NotificationModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markNotificationAsRead(int id) async {
    try {
      final response = await apiClient.post(
        '/api/admin/notifications/$id/read',
        {},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark notification as read');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<NotificationModel>> getPartnerNotifications() async {
    final response = await apiClient.get('/api/partner/notifications');

    if (response.statusCode == 200) {
      final List<dynamic> data =
          apiClient.decodeUtf8Json(response) as List<dynamic>;

      return data.map((e) => NotificationModel.fromJson(e)).toList();
    }

    throw Exception('Không tải được thông báo partner');
  }

  Future<void> markNotificationAsReadPartner(int id) async {
    try {
      final response = await apiClient.post(
        '/api/partner/notifications/$id/read',
        {},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark notification as read');
      }
    } catch (e) {
      rethrow;
    }
  }

  // --- THÊM HÀM NÀY ĐỂ ADMIN GỬI THÔNG BÁO ---
  Future<bool> sendBroadcastNotification({
    required String title,
    required String message,
    String notificationType = 'SYSTEM',
    String? scheduledTime,
  }) async {
    try {
      final payload = {
        "title": title,
        "message": message,
        "notificationType": notificationType,
        "targetType": "GLOBAL",
      };

      final res = await apiClient.post(
        "/api/admin/notifications/broadcast-all",
        payload,
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = apiClient.decodeUtf8Json(res);
        if (body is Map<String, dynamic>) {
          return body['success'] == true;
        }
        return false;
      } else {
        print("Lỗi từ BE: ${res.statusCode} - ${res.body}");
        return false;
      }
    } catch (e) {
      print("Lỗi mạng hoặc ApiClient: $e");
      return false;
    }
  }
}
