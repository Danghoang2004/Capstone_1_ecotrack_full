import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

class UserService {
  final ApiClient apiClient = ApiClient(storage: const FlutterSecureStorage());

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await apiClient.get('/api/user/me');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception: $e');
    }
    return null;
  }
}
