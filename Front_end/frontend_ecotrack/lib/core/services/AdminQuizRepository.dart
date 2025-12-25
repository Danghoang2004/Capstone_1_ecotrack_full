import 'package:file_picker/file_picker.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart'; // Đảm bảo đúng path

class AdminQuizRepository {
  final ApiClient _api;
  AdminQuizRepository(this._api);

  Future<List<dynamic>> fetchAllQuizzes() async {
    final res = await _api.get('/api/admin/quizzes');
    return _api.decodeUtf8Json(res);
  }

  Future<void> deleteQuiz(int id) async {
    await _api.delete('/api/admin/quizzes/$id');
  }

  Future<void> createWithFile({
    required String title,
    required String points,
    required PlatformFile file,
  }) async {
    await _api.postMultipartBytes(
      '/api/admin/quizzes/create-with-import',
      {'title': title, 'pointsReward': points},
      {'file': file.bytes!}, // Truyền bytes cho Web
      file.name,
    );
  }
}
