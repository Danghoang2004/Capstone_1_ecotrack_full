import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/data/models/environment_team_chat_message_model.dart';
import 'package:http/http.dart' as http;

class MembershipRevokedException implements Exception {
  final String message;
  MembershipRevokedException(this.message);
  @override
  String toString() => message;
}

class EnvironmentTeamChatService {
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

  Future<List<EnvironmentTeamChatMessage>> fetchMessages({
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
        ? '/api/environment/team-chat/messages'
        : '/api/environment/team-chat/messages?${params.join('&')}';

    final response = await apiClient.get(path);
    if (response.statusCode != 200) {
      // Check if user was removed from team
      if (response.statusCode == 404) {
        final errorMsg = _extractErrorMessage(response, '');
        if (errorMsg.contains('chưa thuộc') ||
            errorMsg.contains('không tồn tại')) {
          throw MembershipRevokedException(
            'Bạn đã bị xóa khỏi nhóm môi trường.',
          );
        }
      }
      throw Exception(
        _extractErrorMessage(
          response,
          'Không thể tải tin nhắn nhóm môi trường.',
        ),
      );
    }

    final List<dynamic> data = apiClient.decodeUtf8Json(response);
    return data
        .map(
          (item) =>
              EnvironmentTeamChatMessage.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<EnvironmentTeamChatMessage> sendMessage(String message) async {
    final response = await apiClient.post(
      '/api/environment/team-chat/messages',
      {'message': message},
    );

    if (response.statusCode != 200) {
      // Check if user was removed from team
      if (response.statusCode == 404) {
        final errorMsg = _extractErrorMessage(response, '');
        if (errorMsg.contains('chưa thuộc') ||
            errorMsg.contains('không tồn tại')) {
          throw MembershipRevokedException(
            'Bạn đã bị xóa khỏi nhóm môi trường.',
          );
        }
      }
      throw Exception(_extractErrorMessage(response, 'Gửi tin nhắn thất bại.'));
    }

    final Map<String, dynamic> data = apiClient.decodeUtf8Json(response);
    return EnvironmentTeamChatMessage.fromJson(data);
  }

  Future<EnvironmentTeamChatMessage> sendAttachment(String filePath) async {
    final streamed = await apiClient.postMultipart(
      '/api/environment/team-chat/messages/attachments',
      {},
      {'file': filePath},
    );

    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      if (response.statusCode == 404) {
        final errorMsg = _extractErrorMessage(response, '');
        if (errorMsg.contains('chưa thuộc') ||
            errorMsg.contains('không tồn tại')) {
          throw MembershipRevokedException(
            'Bạn đã bị xóa khỏi nhóm môi trường.',
          );
        }
      }
      throw Exception(_extractErrorMessage(response, 'Gửi tệp thất bại.'));
    }

    final Map<String, dynamic> data = apiClient.decodeUtf8Json(response);
    return EnvironmentTeamChatMessage.fromJson(data);
  }
}
