import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  final String baseUrl = 'http://192.168.1.89:8080';
  final FlutterSecureStorage storage;

  ApiClient({required this.storage});

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final token = await storage.read(key: 'jwt_token');
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  Future<http.Response> get(String path) async {
    final token = await storage.read(key: 'jwt_token');
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    return http.get(Uri.parse('$baseUrl$path'), headers: headers);
  }

  Future<http.Response> put(String path, Map<String, dynamic> body) async {
    final token = await storage.read(key: 'jwt_token');
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    return http.put(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  Future<http.Response> delete(String path) async {
    final token = await storage.read(key: 'jwt_token');
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    return http.delete(Uri.parse('$baseUrl$path'), headers: headers);
  }
}
