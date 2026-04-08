import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/data/models/ai_classification/recycle_suggestion_models.dart';

class RecycleSuggestionService {
  final ApiClient _apiClient = ApiClient(storage: const FlutterSecureStorage());

  Future<RecycleSuggestionListResponse> querySuggestions({
    required List<String> wasteTypes,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/user/ai/recycle-suggestions/query',
        {'wasteTypes': wasteTypes},
      );
      final json = _apiClient.decodeUtf8Json(response) as Map<String, dynamic>;
      return RecycleSuggestionListResponse.fromJson(json);
    } catch (e) {
      return RecycleSuggestionListResponse(
        success: false,
        code: 'RECYCLE_SUGGESTION_CLIENT_ERROR',
        message: 'Không thể tải danh sách gợi ý tái chế: $e',
        data: const [],
      );
    }
  }

  Future<RecycleSuggestionDetailResponse> getSuggestionDetail(
    int suggestionId,
  ) async {
    try {
      final response = await _apiClient.get(
        '/api/user/ai/recycle-suggestions/$suggestionId',
      );
      final json = _apiClient.decodeUtf8Json(response) as Map<String, dynamic>;
      return RecycleSuggestionDetailResponse.fromJson(json);
    } catch (e) {
      return RecycleSuggestionDetailResponse(
        success: false,
        code: 'RECYCLE_SUGGESTION_CLIENT_ERROR',
        message: 'Không thể tải chi tiết gợi ý tái chế: $e',
        data: null,
      );
    }
  }
}
