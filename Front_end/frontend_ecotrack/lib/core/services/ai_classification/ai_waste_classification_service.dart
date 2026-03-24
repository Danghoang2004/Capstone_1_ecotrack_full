import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/data/models/ai_classification/ai_waste_classification_models.dart';
import 'package:http/http.dart' as http;

class AiWasteClassificationService {
  final ApiClient _apiClient = ApiClient(storage: const FlutterSecureStorage());

  Future<AiWasteClassificationResponse> classifyWasteImageBytes({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      final streamedResponse = await _apiClient.postMultipartBytes(
        '/api/user/ai/classify-waste',
        const {},
        {'image': imageBytes},
        fileName,
      );

      return _mapResponse(await http.Response.fromStream(streamedResponse));
    } catch (e) {
      return AiWasteClassificationResponse(
        success: false,
        code: 'AI_CLASSIFY_CLIENT_ERROR',
        message: 'Không thể kết nối máy chủ: $e',
      );
    }
  }

  Future<AiWasteClassificationResponse> classifyWasteImagePath(
    String imagePath,
  ) async {
    try {
      final streamedResponse = await _apiClient.postMultipart(
        '/api/user/ai/classify-waste',
        const {},
        {'image': imagePath},
      );

      return _mapResponse(await http.Response.fromStream(streamedResponse));
    } catch (e) {
      return AiWasteClassificationResponse(
        success: false,
        code: 'AI_CLASSIFY_CLIENT_ERROR',
        message: 'Không thể kết nối máy chủ: $e',
      );
    }
  }

  AiWasteClassificationResponse _mapResponse(http.Response response) {
    final json = _apiClient.decodeUtf8Json(response) as Map<String, dynamic>;
    final apiResponse = AiWasteClassificationResponse.fromJson(json);

    if (apiResponse.success) {
      return apiResponse;
    }

    final fallbackMessage = apiResponse.message.isEmpty
        ? 'AI trả về lỗi không xác định.'
        : apiResponse.message;

    return AiWasteClassificationResponse(
      success: false,
      code: apiResponse.code,
      message: fallbackMessage,
      data: apiResponse.data,
    );
  }
}
