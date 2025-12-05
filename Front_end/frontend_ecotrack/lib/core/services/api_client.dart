import 'dart:convert';
import 'package:frontend_ecotrack/presentation/user_app/voucher/rewards_screen.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  final String baseUrl = 'http://192.168.1.4:8080';
  final FlutterSecureStorage storage;

  ApiClient({required this.storage});

  Future<Map<String, String>> _headers({
    bool json = true,
    bool includeJson = true,
  }) async {
    final token = await storage.read(key: 'jwt_token');

    final map = <String, String>{};

    if (json) {
      map['Content-Type'] = 'application/json; charset=utf-8';
    }

    map['Accept'] = 'application/json; charset=utf-8';
    map['Accept-Charset'] = 'utf-8';

    if (token != null) {
      map['Authorization'] = 'Bearer $token';
    }

    return map;
  }

  Future<http.Response> get(String path) async {
    final headers = await _headers(json: false);
    return http.get(Uri.parse('$baseUrl$path'), headers: headers);
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final headers = await _headers(json: true);
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  Future<http.Response> put(String path, Map<String, dynamic> body) async {
    final headers = await _headers(json: true);
    return http.put(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  Future<http.Response> delete(String path) async {
    final headers = await _headers(json: false);
    return http.delete(Uri.parse('$baseUrl$path'), headers: headers);
  }

  Future<http.StreamedResponse> postMultipart(
    String path,
    Map<String, String> fields,
    Map<String, String> files,
  ) async {
    final token = await storage.read(key: 'jwt_token');

    var request = http.MultipartRequest("POST", Uri.parse('$baseUrl$path'));

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    fields.forEach((key, value) => request.fields[key] = value);

    for (var file in files.entries) {
      request.files.add(
        await http.MultipartFile.fromPath(file.key, file.value),
      );
    }

    return await request.send();
  }

  dynamic decodeUtf8Json(http.Response response) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  }
}

/// ======================
/// VoucherApi dùng ApiClient
/// ======================
class VoucherApi {
  final ApiClient _client;

  VoucherApi(this._client);

  /// Lấy danh sách voucher từ BE
  Future<List<RewardItem>> fetchRewards() async {
    final res = await _client.get('/api/v1/vouchers');

    if (res.statusCode == 200) {
      final List data = _client.decodeUtf8Json(res);
      return data.map((e) => RewardItem.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load vouchers: ${res.body}');
    }
  }

  /// Gọi API đổi voucher
  Future<void> redeemVoucher(int voucherId, int userId) async {
    final res = await _client.post(
      '/api/v1/vouchers/$voucherId/redeem?userId=$userId',
      {}, // body rỗng
    );

    if (res.statusCode != 200) {
      throw Exception('Redeem failed: ${res.body}');
    }
  }

  /// Lấy điểm user cho màn voucher
  Future<int> fetchUserPoints(int userId) async {
    final res = await _client.get('/api/v1/vouchers/user/$userId/voucher-page');

    if (res.statusCode == 200) {
      final Map<String, dynamic> data = _client.decodeUtf8Json(res);
      return (data['points'] ?? 0) as int;
    } else {
      throw Exception('Failed to load user points: ${res.body}');
    }
  }
}
