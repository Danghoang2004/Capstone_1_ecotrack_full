import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/data/models/ai_classification/classification_history_models.dart';

class ClassificationHistoryService {
  final ApiClient _apiClient = ApiClient(storage: const FlutterSecureStorage());

  Future<ClassificationHistoryListResponse> getClassificationHistory() async {
    try {
      final response = await _apiClient.get(
        '/api/user/ai/classification-history',
      );
      final json = _apiClient.decodeUtf8Json(response) as Map<String, dynamic>;
      return ClassificationHistoryListResponse.fromJson(json);
    } catch (e) {
      return ClassificationHistoryListResponse(
        success: false,
        code: 'ERROR',
        message: e.toString(),
        data: [],
      );
    }
  }

  Future<ClassificationHistoryDetailResponse> getHistoryDetail(
    int historyId,
  ) async {
    try {
      final response = await _apiClient.get(
        '/api/user/ai/classification-history/$historyId',
      );
      final json = _apiClient.decodeUtf8Json(response) as Map<String, dynamic>;
      return ClassificationHistoryDetailResponse.fromJson(json);
    } catch (e) {
      return ClassificationHistoryDetailResponse(
        success: false,
        code: 'ERROR',
        message: e.toString(),
      );
    }
  }
}
