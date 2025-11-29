import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';

class CouponService {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  late final ApiClient apiClient = ApiClient(storage: storage);

  Future<List<Map<String, dynamic>>> getAllCoupons() async {
    final response = await apiClient.get("/api/partner/coupons");

    if (response.statusCode == 401) {
      return [];
    }

    if (response.statusCode != 200) {
      throw Exception("Lỗi server: ${response.statusCode}");
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return List<Map<String, dynamic>>.from(body);
  }

  Future<Map<String, dynamic>> createCoupon(Map<String, dynamic> data) async {
    final response = await apiClient.post("/api/partner/coupons", data);

    if (response.statusCode == 401) {
      throw UnauthorizedException("Token expired");
    }

    if (response.statusCode != 201) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(
        "Lỗi tạo coupon: ${body['message'] ?? response.statusCode}",
      );
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return Map<String, dynamic>.from(body);
  }

  Future<Map<String, dynamic>> updateCoupon(
    int couponId,
    Map<String, dynamic> data,
  ) async {
    final response = await apiClient.put(
      "/api/partner/coupons/$couponId",
      data,
    );

    if (response.statusCode == 401) {
      throw UnauthorizedException("Token expired");
    }

    if (response.statusCode != 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(
        "Lỗi cập nhật coupon: ${body['message'] ?? response.statusCode}",
      );
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return Map<String, dynamic>.from(body);
  }

  Future<void> deleteCoupon(int couponId) async {
    final response = await apiClient.delete("/api/partner/coupons/$couponId");

    if (response.statusCode == 401) {
      throw UnauthorizedException("Token expired");
    }

    if (response.statusCode != 204) {
      throw Exception("Lỗi xóa coupon: ${response.statusCode}");
    }
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final response = await apiClient.get("/api/partner/coupons/statistics");

    if (response.statusCode == 401) {
      throw UnauthorizedException("Token expired");
    }

    if (response.statusCode != 200) {
      throw Exception("Lỗi lấy thống kê: ${response.statusCode}");
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return Map<String, dynamic>.from(body);
  }
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
  @override
  String toString() => message;
}
