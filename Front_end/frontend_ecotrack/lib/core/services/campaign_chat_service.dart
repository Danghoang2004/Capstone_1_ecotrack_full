import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/data/models/campaign_chat_message_model.dart';
import 'package:http/http.dart' as http;

class CampaignChatAccessException implements Exception {
  final String message;
  CampaignChatAccessException(this.message);
  @override
  String toString() => message;
}

class CampaignChatService {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  late final ApiClient apiClient = ApiClient(storage: storage);

  String _extractErrorMessage(dynamic response, String fallback) {
    try {
      final decoded = apiClient.decodeUtf8Json(response);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'] ?? decoded['error'];
        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString().trim();
        }
      }

      if (decoded is String && decoded.trim().isNotEmpty) {
        return decoded.trim();
      }
    } catch (_) {}

    final body = response.body?.toString().trim() ?? '';
    if (body.isNotEmpty) {
      return body;
    }

    return fallback;
  }

  bool _isAccessError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('chưa tham gia') ||
        lower.contains('không tìm thấy') ||
        lower.contains('không tồn tại') ||
        lower.contains('vui lòng đăng nhập');
  }

  Future<List<CampaignChatMessage>> fetchMessages({
    required int campaignId,
    int? afterMessageId,
    int limit = 80,
  }) async {
    final params = <String>[];
    if (afterMessageId != null && afterMessageId > 0) {
      params.add('afterMessageId=$afterMessageId');
    }
    if (limit > 0) {
      params.add('limit=$limit');
    }

    final path = params.isEmpty
        ? '/api/campaigns/$campaignId/chat/messages'
        : '/api/campaigns/$campaignId/chat/messages?${params.join('&')}';

    final response = await apiClient.get(path);
    if (response.statusCode != 200) {
      final errorMsg = _extractErrorMessage(
        response,
        'Không thể tải tin nhắn chiến dịch.',
      );
      if (_isAccessError(errorMsg)) {
        throw CampaignChatAccessException('Bạn chưa tham gia chiến dịch này.');
      }
      throw Exception(errorMsg);
    }

    final List<dynamic> data = apiClient.decodeUtf8Json(response);
    return data
        .map(
          (item) => CampaignChatMessage.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<CampaignChatMessage> sendMessage({
    required int campaignId,
    required String message,
  }) async {
    final response = await apiClient.post(
      '/api/campaigns/$campaignId/chat/messages',
      {'message': message},
    );

    if (response.statusCode != 200) {
      final errorMsg = _extractErrorMessage(response, 'Gửi tin nhắn thất bại.');
      if (_isAccessError(errorMsg)) {
        throw CampaignChatAccessException('Bạn chưa tham gia chiến dịch này.');
      }
      throw Exception(errorMsg);
    }

    final Map<String, dynamic> data = apiClient.decodeUtf8Json(response);
    return CampaignChatMessage.fromJson(data);
  }

  Future<CampaignChatMessage> sendAttachment({
    required int campaignId,
    required String filePath,
  }) async {
    final streamed = await apiClient.postMultipart(
      '/api/campaigns/$campaignId/chat/messages/attachments',
      {},
      {'file': filePath},
    );

    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200) {
      final errorMsg = _extractErrorMessage(response, 'Gửi tệp thất bại.');
      if (_isAccessError(errorMsg)) {
        throw CampaignChatAccessException('Bạn chưa tham gia chiến dịch này.');
      }
      throw Exception(errorMsg);
    }

    final Map<String, dynamic> data = apiClient.decodeUtf8Json(response);
    return CampaignChatMessage.fromJson(data);
  }
}
