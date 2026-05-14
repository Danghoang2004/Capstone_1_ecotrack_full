import 'dart:convert';
import 'dart:typed_data';

import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class BadgeModel {
  final int badgeId;
  final String badgeName;
  final String description;
  final String iconUrl;
  final String requirement;
  final int pointsRequired;

  BadgeModel({
    required this.badgeId,
    required this.badgeName,
    required this.description,
    required this.iconUrl,
    required this.requirement,
    required this.pointsRequired,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      badgeId: (json['badgeId'] as num).toInt(),
      badgeName: json['badgeName'] ?? '',
      description: json['description'] ?? '',
      iconUrl: json['iconUrl'] ?? '',
      requirement: json['requirement'] ?? '',
      pointsRequired: (json['pointsRequired'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'badgeName': badgeName,
      'description': description,
      'iconUrl': iconUrl,
      'requirement': requirement,
      'pointsRequired': pointsRequired,
    };
  }
}

class AdminBadgeService {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  late final ApiClient apiClient = ApiClient(storage: storage);

  Future<List<BadgeModel>> getAllBadges() async {
    try {
      final res = await apiClient.get("/api/admin/badges");
      if (res.statusCode == 200) {
        final body = apiClient.decodeUtf8Json(res) as List<dynamic>;
        return body.map((e) {
          final json = Map<String, dynamic>.from(e as Map<String, dynamic>);
          final rawIcon = (json['iconUrl'] ?? '').toString();
          json['iconUrl'] = apiClient.buildImageUrl(rawIcon);
          return BadgeModel.fromJson(json);
        }).toList();
      }
      throw Exception("Lỗi tải danh sách huy hiệu: ${res.statusCode}");
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUsersForAwarding() async {
    try {
      final res = await apiClient.get("/api/admin/badges/users");
      if (res.statusCode == 200) {
        final body = apiClient.decodeUtf8Json(res) as List<dynamic>;
        return body.cast<Map<String, dynamic>>();
      }
      throw Exception("Lỗi tải danh sách người dùng: ${res.statusCode}");
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createBadge({
    required String badgeName,
    required String description,
    required String iconUrl,
    required String requirement,
    required int pointsRequired,
  }) async {
    try {
      final payload = {
        'badgeName': badgeName,
        'description': description,
        'iconUrl': iconUrl,
        'requirement': requirement,
        'pointsRequired': pointsRequired,
      };
      final res = await apiClient.post('/api/admin/badges', payload);
      if (res.statusCode == 200) {
        final body = apiClient.decodeUtf8Json(res) as Map<String, dynamic>;
        return body;
      }
      throw Exception("Tạo huy hiệu thất bại: ${res.statusCode}");
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createBadgeWithImage({
    required String badgeName,
    required String description,
    required String requirement,
    required int pointsRequired,
    required Uint8List imageBytes,
    required String imageFileName,
  }) async {
    final data = {
      'badgeName': badgeName,
      'description': description,
      'iconUrl': '',
      'requirement': requirement,
      'pointsRequired': pointsRequired,
    };

    final streamed = await apiClient.postMultipartBytes(
      '/api/admin/badges/upload',
      {'data': jsonEncode(data)},
      {'image': imageBytes},
      imageFileName,
    );

    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 200) {
      return apiClient.decodeUtf8Json(response) as Map<String, dynamic>;
    }
    throw Exception('Tạo huy hiệu thất bại: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> updateBadge({
    required int badgeId,
    required String badgeName,
    required String description,
    required String iconUrl,
    required String requirement,
    required int pointsRequired,
  }) async {
    try {
      final payload = {
        'badgeName': badgeName,
        'description': description,
        'iconUrl': iconUrl,
        'requirement': requirement,
        'pointsRequired': pointsRequired,
      };
      final res = await apiClient.put('/api/admin/badges/$badgeId', payload);
      if (res.statusCode == 200) {
        final body = apiClient.decodeUtf8Json(res) as Map<String, dynamic>;
        return body;
      }
      throw Exception("Cập nhật huy hiệu thất bại: ${res.statusCode}");
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateBadgeWithImage({
    required int badgeId,
    required String badgeName,
    required String description,
    required String requirement,
    required int pointsRequired,
    required Uint8List imageBytes,
    required String imageFileName,
  }) async {
    final data = {
      'badgeName': badgeName,
      'description': description,
      'iconUrl': '',
      'requirement': requirement,
      'pointsRequired': pointsRequired,
    };

    final streamed = await apiClient.putMultipartBytes(
      '/api/admin/badges/$badgeId/upload',
      {'data': jsonEncode(data)},
      {'image': imageBytes},
      imageFileName,
    );

    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 200) {
      return apiClient.decodeUtf8Json(response) as Map<String, dynamic>;
    }
    throw Exception('Cập nhật huy hiệu thất bại: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> deleteBadge(int badgeId) async {
    try {
      final res = await apiClient.delete('/api/admin/badges/$badgeId');
      if (res.statusCode == 200) {
        final body = apiClient.decodeUtf8Json(res) as Map<String, dynamic>;
        return body;
      }
      throw Exception("Xóa huy hiệu thất bại: ${res.statusCode}");
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> awardBadge({
    required int userId,
    required int badgeId,
  }) async {
    try {
      final payload = {
        'userId': userId,
        'badgeId': badgeId,
      };
      final res = await apiClient.post('/api/admin/badges/award', payload);
      if (res.statusCode == 200) {
        final body = apiClient.decodeUtf8Json(res) as Map<String, dynamic>;
        return body;
      }
      throw Exception("Trao huy hiệu thất bại: ${res.statusCode}");
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> removeBadgeFromUser({
    required int badgeId,
    required int userId,
  }) async {
    try {
      final res = await apiClient.delete('/api/admin/badges/$badgeId/users/$userId');
      if (res.statusCode == 200) {
        final body = apiClient.decodeUtf8Json(res) as Map<String, dynamic>;
        return body;
      }
      throw Exception("Thu hồi huy hiệu thất bại: ${res.statusCode}");
    } catch (e) {
      rethrow;
    }
  }
}
