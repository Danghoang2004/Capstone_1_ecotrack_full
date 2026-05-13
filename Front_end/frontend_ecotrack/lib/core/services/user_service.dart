// lib/core/services/user_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/data/models/ProfileView.dart';
import 'package:http/http.dart' as http;

class UserService {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  late final ApiClient apiClient = ApiClient(storage: storage);

  static ProfileView? _cachedProfile;
  static DateTime? _profileCachedAt;
  static Future<ProfileView>? _inFlightProfileRequest;
  static const Duration _profileCacheTtl = Duration(seconds: 8);

  static void clearProfileCache() {
    _cachedProfile = null;
    _profileCachedAt = null;
    _inFlightProfileRequest = null;
  }

  Future<ProfileView> getProfileView({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedProfile != null &&
        _profileCachedAt != null &&
        DateTime.now().difference(_profileCachedAt!) < _profileCacheTtl) {
      return _cachedProfile!;
    }

    if (!forceRefresh && _inFlightProfileRequest != null) {
      return _inFlightProfileRequest!;
    }

    _inFlightProfileRequest = _fetchProfileView();
    try {
      final profile = await _inFlightProfileRequest!;
      _cachedProfile = profile;
      _profileCachedAt = DateTime.now();
      return profile;
    } finally {
      _inFlightProfileRequest = null;
    }
  }

  Future<ProfileView> _fetchProfileView() async {
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

  Future<List<Map<String, dynamic>>> getAllEnvironmentUsers() async {
    final response = await apiClient.get("/api/admin/environment/users");

    if (response.statusCode == 401) {
      return [];
    }

    if (response.statusCode != 200) {
      throw Exception("Lỗi server: ${response.statusCode}");
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return List<Map<String, dynamic>>.from(body);
  }

  Future<void> updateEnvironmentUser(int userId, Map<String, dynamic> data) async {
    final response = await apiClient.put("/api/admin/environment/users/$userId", data);

    if (response.statusCode == 401) {
      return;
    }

    if (response.statusCode != 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final error = body['error'] ?? 'Lỗi server: ${response.statusCode}';
      throw Exception(error);
    }
  }

  Future<void> deleteEnvironmentUser(int userId) async {
    final response = await apiClient.delete("/api/admin/environment/users/$userId");

    if (response.statusCode == 401) {
      return;
    }

    if (response.statusCode != 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final error = body['error'] ?? 'Lỗi server: ${response.statusCode}';
      throw Exception(error);
    }
  }

  Future<void> deleteEnvironmentUsers(List<int> userIds) async {
    final response = await apiClient.post("/api/admin/environment/users/bulk/delete", {
      'userIds': userIds,
    });

    if (response.statusCode == 401) {
      return;
    }

    if (response.statusCode != 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final error = body['error'] ?? 'Lỗi server: ${response.statusCode}';
      throw Exception(error);
    }
  }

  Future<void> updateProfileFull({
    required String fullName,
    required String location,
    required String phoneNumber,
    String? currentPassword,
    String? newPassword,
    String? confirmPassword,
    Uint8List? avatarBytes,
    String? avatarFilename,
  }) async {
    // SỬA Ở ĐÂY: Lấy baseUrl từ đối tượng apiClient
    // apiClient.baseUrl là thuộc tính public bạn đã khai báo trong class ApiClient
    var uri = Uri.parse('${apiClient.baseUrl}/api/user/profile/update');

    var request = http.MultipartRequest('POST', uri);

    // Thêm Token
    final token = await storage.read(key: 'jwt_token');
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Thêm các fields text
    request.fields['fullName'] = fullName;
    request.fields['location'] = location;
    request.fields['phoneNumber'] = phoneNumber;

    if (currentPassword != null && currentPassword.isNotEmpty) {
      request.fields['currentPassword'] = currentPassword;
    }
    if (newPassword != null && newPassword.isNotEmpty) {
      request.fields['newPassword'] = newPassword;
    }
    if (confirmPassword != null && confirmPassword.isNotEmpty) {
      request.fields['confirmPassword'] = confirmPassword;
    }

    // Thêm file ảnh (nếu có)
    if (avatarBytes != null && avatarBytes.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'avatar', // Key này phải trùng với @RequestParam("avatar") ở Java
          avatarBytes,
          filename: avatarFilename ?? 'avatar.jpg',
        ),
      );
    }

    // Gửi request
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      // Decode để lấy thông báo lỗi chi tiết từ backend
      String errorMsg = response.body;
      try {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body is Map && body.containsKey('error')) {
          errorMsg =
              body['error']; // Lấy message lỗi cụ thể (ví dụ: "Sai mật khẩu")
        } else if (body is Map && body.containsKey('message')) {
          errorMsg = body['message'];
        }
      } catch (_) {}

      throw Exception(errorMsg);
    }

    clearProfileCache();
  }

  Future<List<BadgeModel>> getAllBadges() async {
    // 1. Gọi API bằng apiClient
    final response = await apiClient.get("/api/user/badges/all");

    // 2. Xử lý lỗi Token hết hạn
    if (response.statusCode == 401) {
      throw UnauthorizedException("Token expired");
    }

    // 3. Xử lý lỗi Server
    if (response.statusCode != 200) {
      throw Exception("Lỗi server: ${response.statusCode}");
    }

    // 4. Parse dữ liệu thành JSON
    final body = jsonDecode(utf8.decode(response.bodyBytes));

    // 5. Trỏ đúng vào key 'data' giống y hệt cấu trúc JSON từ Postman bạn vừa gửi
    if (body['success'] == true && body['data'] != null) {
      final List<dynamic> dataList = body['data'];
      return dataList.map((json) => BadgeModel.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  // Lấy tiến độ huy hiệu của user (bao gồm badges đã đạt và chưa đạt)
  Future<Map<String, dynamic>> getBadgeProgress() async {
    // 1. Gọi API với authentication token
    final response = await apiClient.get("/api/user/badges/progress");

    // 2. Xử lý lỗi Token hết hạn
    if (response.statusCode == 401) {
      throw UnauthorizedException("Token expired");
    }

    // 3. Xử lý lỗi Server
    if (response.statusCode != 200) {
      throw Exception("Lỗi server: ${response.statusCode}");
    }

    // 4. Parse dữ liệu thành JSON
    final body = jsonDecode(utf8.decode(response.bodyBytes));

    // 5. Trỏ đúng vào key 'data' - giờ data là object chứa currentPoints + badges
    if (body['success'] == true && body['data'] != null) {
      return body['data'];
    } else {
      return {'currentPoints': 0, 'badges': []};
    }
  }

  // Helper method để extract badges từ progress response
  Future<List<BadgeModel>> getBadgeProgressBadges() async {
    final progressData = await getBadgeProgress();
    final badgesData = progressData['badges'] as List<dynamic>? ?? [];
    return badgesData.map((json) => BadgeModel.fromJson(json)).toList();
  }

  // Helper method để lấy current points
  Future<int> getCurrentBadgePoints() async {
    final progressData = await getBadgeProgress();
    return progressData['currentPoints'] as int? ?? 0;
  }
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = 'Unauthorized']);
  @override
  String toString() => 'UnauthorizedException: $message';
}
