import 'dart:convert';
import 'package:frontend_ecotrack/data/models/quiz_models.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  final String baseUrl = 'http://192.168.1.6:8080';
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
