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

  Future<int> getUnreadCount() async {
    // Use /api/notifications (full list) and count client-side by 'read' flag.
    // This keeps badge consistent with the list shown in NotificationScreen.
    final res = await apiClient.get('/api/notifications');
    if (res.statusCode != 200) {
      throw Exception('Không tải được thông báo');
    }

    final body = apiClient.decodeUtf8Json(res);
    if (body is List) {
      int cnt = 0;
      for (final e in body) {
        if (e is Map<String, dynamic>) {
          final readVal = e['read'];
          if (readVal is bool) {
            if (!readVal) cnt++;
          } else if (readVal is num) {
            if (readVal == 0) cnt++; // 0 => unread
          } else if (readVal == null) {
            // If field missing, assume unread
            cnt++;
          }
        } else if (e is Map) {
          final readVal = e['read'];
          if (readVal is bool) {
            if (!readVal) cnt++;
          } else if (readVal is num) {
            if (readVal == 0) cnt++;
          } else if (readVal == null) {
            cnt++;
          }
        }
      }
      return cnt;
    }

    // fallback: try /unread endpoint
    final alt = await apiClient.get('/api/notifications/unread');
    if (alt.statusCode == 200) {
      final altBody = apiClient.decodeUtf8Json(alt);
      if (altBody is List) return altBody.length;
      if (altBody is int) return altBody;
    }
    return 0;
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
    required String audienceRole,
    String notificationType = 'SYSTEM',
    String? scheduledTime,
  }) async {
    try {
      final payload = {
        "title": title,
        "message": message,
        "notificationType": notificationType,
        "targetType": audienceRole,
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

  Future<bool> updateAdminNotification({
    required int id,
    required String title,
    required String message,
  }) async {
    try {
      final payload = {
        'title': title,
        'message': message,
      };

      final res = await apiClient.put('/api/admin/notifications/$id', payload);
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAdminNotification(int id) async {
    try {
      final res = await apiClient.delete('/api/admin/notifications/$id');
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isAdminNotificationEditDeleteSupported() async {
    try {
      final res = await apiClient.get('/api/admin/notifications');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
