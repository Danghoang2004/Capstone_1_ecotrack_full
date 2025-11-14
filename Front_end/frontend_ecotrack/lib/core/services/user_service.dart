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

    if (response.statusCode == 401) {
      throw UnauthorizedException("Token expired");
    }

    if (response.statusCode != 200) {
      throw Exception("Lỗi server: ${response.statusCode}");
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return ProfileView.fromJson(body);
  }
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = 'Unauthorized']);
  @override
  String toString() => 'UnauthorizedException: $message';
}
