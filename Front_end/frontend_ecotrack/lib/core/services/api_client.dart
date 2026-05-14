import 'dart:convert';

import 'dart:typed_data';
import 'package:frontend_ecotrack/data/models/quiz_models.dart';
import 'package:frontend_ecotrack/presentation/user_app/voucher/rewards_screen.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend_ecotrack/core/services/session_service.dart';

class ApiClient {
  final String baseUrl = dotenv.env['API_BASE_URL']!;
  final FlutterSecureStorage storage;
  ApiClient({required this.storage});
  Future<http.Response> _handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      await SessionService.handleSessionExpired();
    }
    return response;
  }

  String buildImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith("http")) return path;
    return "$baseUrl$path";
  }

  Future<Map<String, String>> _headers({bool json = true}) async {
    final token = await storage.read(key: 'jwt_token');

    final map = <String, String>{};

    if (json) {
      map['Content-Type'] = 'application/json; charset=utf-8';
    }
    map['Accept'] = 'application/json; charset=utf-8';
    if (token != null) {
      map['Authorization'] = 'Bearer $token';
    }

    return map;
  }

  Future<http.Response> get(String path) async {
    final headers = await _headers(json: false);
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final headers = await _headers(json: true);
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<http.Response> put(String path, Map<String, dynamic> body) async {
    final headers = await _headers(json: true);
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<http.Response> delete(String path) async {
    final headers = await _headers(json: false);
    final response = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: headers,
    );
    return _handleResponse(response);
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

  Future<http.StreamedResponse> postMultipartBytes(
    String path,
    Map<String, String> fields,
    Map<String, Uint8List> files,
    String fileName,
  ) async {
    final token = await storage.read(key: 'jwt_token');

    var request = http.MultipartRequest("POST", Uri.parse('$baseUrl$path'));

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    fields.forEach((key, value) => request.fields[key] = value);

    for (var file in files.entries) {
      request.files.add(
        http.MultipartFile.fromBytes(file.key, file.value, filename: fileName),
      );
    }

    return await request.send();
  }

  Future<http.StreamedResponse> putMultipartBytes(
    String path,
    Map<String, String> fields,
    Map<String, Uint8List> files,
    String fileName,
  ) async {
    final token = await storage.read(key: 'jwt_token');

    var request = http.MultipartRequest("PUT", Uri.parse('$baseUrl$path'));

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    fields.forEach((key, value) => request.fields[key] = value);

    for (var file in files.entries) {
      request.files.add(
        http.MultipartFile.fromBytes(file.key, file.value, filename: fileName),
      );
    }

    return await request.send();
  }

  dynamic decodeUtf8Json(http.Response response) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  }
}

class QuizRepository {
  // tạo 1 ApiClient dùng chung cho quiz
  final ApiClient _api = ApiClient(storage: const FlutterSecureStorage());

  Future<QuizDetail> getQuiz(int quizId) async {
    final http.Response res = await _api.get('/api/quizzes/$quizId');

    if (res.statusCode >= 400) {
      throw Exception('Lỗi gọi API quiz: ${res.statusCode} - ${res.body}');
    }

    final data = _api.decodeUtf8Json(res);
    return QuizDetail.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<SubmitResponse> submit(int quizId, Map<int, String> answers) async {
    final payload = {
      'answers': answers.entries
          .map((e) => {'questionId': e.key, 'selected': e.value})
          .toList(),
    };

    final res = await _api.post('/api/quizzes/$quizId/submit', payload);
    final data = _api.decodeUtf8Json(res);
    return SubmitResponse.fromJson((data as Map).cast<String, dynamic>());
  }
}

class QuizOverviewRepository {
  final ApiClient _api;

  QuizOverviewRepository(this._api);

  Future<List<QuizOverviewItem>> fetchQuizOverview() async {
    final res = await _api.get(
      '/api/quizzes/overview',
    ); // nếu bạn có API list quiz
    final data = _api.decodeUtf8Json(res);

    return (data as List)
        .map(
          (e) => QuizOverviewItem.fromJson((e as Map).cast<String, dynamic>()),
        )
        .toList();
  }

  // gọi API /summary để lấy điểm tích lũy
  Future<QuizSummary> fetchSummary() async {
    final res = await _api.get('/api/quizzes/summary');
    final data = _api.decodeUtf8Json(res);
    return QuizSummary.fromJson((data as Map).cast<String, dynamic>());
  }
}

class VoucherApi {
  final ApiClient _client;

  VoucherApi(this._client);

  /// Lấy danh sách voucher từ BE
  Future<List<RewardItem>> fetchRewards() async {
    final res = await _client.get('/api/v1/vouchers');

    if (res.statusCode == 200) {
      final List data = _client.decodeUtf8Json(res);
      return data.map((e) => RewardItem.fromJson(e, _client)).toList();
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
