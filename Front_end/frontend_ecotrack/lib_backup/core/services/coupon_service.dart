import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
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
      // Kiểm tra xem response body có rỗng không
      final bodyBytes = response.bodyBytes;
      if (bodyBytes.isEmpty) {
        throw Exception("Lỗi tạo coupon: ${response.statusCode}");
      }
      try {
        final body = jsonDecode(utf8.decode(bodyBytes));
        throw Exception(
          "Lỗi tạo coupon: ${body['message'] ?? body['error'] ?? response.statusCode}",
        );
      } catch (e) {
        throw Exception("Lỗi tạo coupon: ${response.statusCode}");
      }
    }

    // Kiểm tra xem response body có rỗng không
    final bodyBytes = response.bodyBytes;
    if (bodyBytes.isEmpty) {
      // Nếu body rỗng nhưng status là 201, trả về empty map
      return <String, dynamic>{};
    }

    try {
      final body = jsonDecode(utf8.decode(bodyBytes));
      return Map<String, dynamic>.from(body);
    } catch (e) {
      // Nếu không parse được JSON, trả về empty map
      return <String, dynamic>{};
    }
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

  Future<String> uploadImage(String imagePath) async {
    final streamedResponse = await apiClient.postMultipart(
      "/api/partner/coupons/upload-image",
      {},
      {"image": imagePath},
    );

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 401) {
      throw UnauthorizedException("Token expired");
    }

    if (response.statusCode != 200) {
      throw Exception("Lỗi upload ảnh: ${response.statusCode}");
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return body['imageUrl'] as String;
  }

  Future<String> uploadImageBytes(Uint8List imageBytes, String fileName) async {
    final streamedResponse = await apiClient.postMultipartBytes(
      "/api/partner/coupons/upload-image",
      {},
      {"image": imageBytes},
      fileName,
    );

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 401) {
      throw UnauthorizedException("Token expired");
    }

    if (response.statusCode != 200) {
      throw Exception("Lỗi upload ảnh: ${response.statusCode}");
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return body['imageUrl'] as String;
  }
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
  @override
  String toString() => message;
}
