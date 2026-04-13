import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/data/models/admin_environment_team_models.dart';

class AdminEnvironmentTeamService {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  late final ApiClient apiClient = ApiClient(storage: storage);

  Future<List<EnvironmentTeam>> fetchTeams() async {
    final response = await apiClient.get('/api/admin/environment/teams');
    if (response.statusCode != 200) {
      throw Exception('Không thể tải danh sách đội môi trường.');
    }

    final List<dynamic> data = apiClient.decodeUtf8Json(response);
    return data
        .map((item) => EnvironmentTeam.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<EnvironmentTeamKpi>> fetchKpis({
    String? fromAt,
    String? toAt,
  }) async {
    final params = <String>[];
    if (fromAt != null && fromAt.isNotEmpty) {
      params.add('fromAt=${Uri.encodeComponent(fromAt)}');
    }
    if (toAt != null && toAt.isNotEmpty) {
      params.add('toAt=${Uri.encodeComponent(toAt)}');
    }

    final path = params.isEmpty
        ? '/api/admin/environment/teams/kpi'
        : '/api/admin/environment/teams/kpi?${params.join('&')}';
    final response = await apiClient.get(path);
    if (response.statusCode != 200) {
      throw Exception('Không thể tải KPI đội môi trường.');
    }

    final List<dynamic> data = apiClient.decodeUtf8Json(response);
    return data
        .map(
          (item) => EnvironmentTeamKpi.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<EnvironmentTeamUserOption>> fetchUsers() async {
    final response = await apiClient.get(
      '/api/admin/environment/teams/environment-users',
    );
    if (response.statusCode != 200) {
      throw Exception('Không thể tải danh sách người dùng môi trường.');
    }

    final List<dynamic> data = apiClient.decodeUtf8Json(response);
    return data
        .map(
          (item) =>
              EnvironmentTeamUserOption.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> createTeam({
    required String teamName,
    required String description,
    required int leadUserId,
  }) async {
    final response = await apiClient.post('/api/admin/environment/teams', {
      'teamName': teamName,
      'description': description,
      'leadUserId': leadUserId,
      'memberUserIds': <int>[],
    });

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(response, 'Tạo đội thất bại.'));
    }
  }

  Future<void> updateTeam({
    required int teamId,
    String? teamName,
    String? description,
    bool? isActive,
  }) async {
    final payload = <String, dynamic>{};
    if (teamName != null) payload['teamName'] = teamName;
    if (description != null) payload['description'] = description;
    if (isActive != null) payload['isActive'] = isActive;

    final response = await apiClient.put(
      '/api/admin/environment/teams/$teamId',
      payload,
    );
    if (response.statusCode != 200) {
      throw Exception(_extractMessage(response, 'Cập nhật đội thất bại.'));
    }
  }

  Future<void> setTeamLead({required int teamId, required int userId}) async {
    final response = await apiClient.put(
      '/api/admin/environment/teams/$teamId/lead/$userId',
      {},
    );
    if (response.statusCode != 200) {
      throw Exception(_extractMessage(response, 'Đổi lead thất bại.'));
    }
  }

  Future<void> addMember({required int teamId, required int userId}) async {
    final response = await apiClient.post(
      '/api/admin/environment/teams/$teamId/members/$userId',
      {},
    );
    if (response.statusCode != 200) {
      throw Exception(_extractMessage(response, 'Thêm thành viên thất bại.'));
    }
  }

  Future<void> removeMember({required int teamId, required int userId}) async {
    final response = await apiClient.delete(
      '/api/admin/environment/teams/$teamId/members/$userId',
    );
    if (response.statusCode != 200) {
      throw Exception(_extractMessage(response, 'Xoá thành viên thất bại.'));
    }
  }

  String _extractMessage(dynamic response, String fallback) {
    try {
      final decoded = apiClient.decodeUtf8Json(response);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'] ?? decoded['error'];
        if (message != null && message.toString().isNotEmpty) {
          return message.toString();
        }
      }
    } catch (_) {}
    return fallback;
  }
}
