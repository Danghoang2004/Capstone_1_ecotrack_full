import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/data/models/environment_cleanup_task_model.dart';
import 'package:frontend_ecotrack/data/models/environment_team_lead_model.dart';

class AdminEnvironmentTaskService {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  late final ApiClient apiClient = ApiClient(storage: storage);

  Future<List<EnvironmentCleanupTask>> fetchAllTasks() async {
    final response = await apiClient.get('/api/admin/environment/tasks');
    if (response.statusCode != 200) {
      throw Exception('Không thể tải danh sách phân công môi trường.');
    }

    final List<dynamic> data = apiClient.decodeUtf8Json(response);
    return data
        .map(
          (item) =>
              EnvironmentCleanupTask.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<EnvironmentTeamLead>> fetchEnvironmentTeamLeads() async {
    final response = await apiClient.get(
      '/api/admin/environment/tasks/team-leads',
    );
    if (response.statusCode != 200) {
      throw Exception('Không thể tải danh sách team lead môi trường.');
    }

    final List<dynamic> data = apiClient.decodeUtf8Json(response);
    return data
        .map(
          (item) => EnvironmentTeamLead.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> assignTask({
    required int reportId,
    required int teamLeadUserId,
    String? assignmentNote,
    String? plannedStartAt,
    String? plannedEndAt,
    String? dueAt,
  }) async {
    final response = await apiClient
        .post('/api/admin/environment/tasks/assign', {
          'reportId': reportId,
          'teamLeadUserId': teamLeadUserId,
          'assignmentNote': assignmentNote,
          'plannedStartAt': plannedStartAt,
          'plannedEndAt': plannedEndAt,
          'dueAt': dueAt,
        });

    if (response.statusCode != 200) {
      final decoded = apiClient.decodeUtf8Json(response);
      final message = decoded is Map<String, dynamic>
          ? decoded['message']
          : null;
      throw Exception(message?.toString() ?? 'Phân công thất bại.');
    }
  }

  Future<void> resolveTask(int taskId) async {
    final response = await apiClient.put(
      '/api/admin/environment/tasks/$taskId/resolve',
      {},
    );
    if (response.statusCode != 200) {
      final decoded = apiClient.decodeUtf8Json(response);
      final message = decoded is Map<String, dynamic>
          ? decoded['message']
          : null;
      throw Exception(message?.toString() ?? 'Xác nhận hoàn tất thất bại.');
    }
  }
}
