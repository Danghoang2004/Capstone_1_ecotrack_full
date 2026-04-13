import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/data/models/environment_cleanup_task_model.dart';
import 'package:http/http.dart' as http;

class TaskDestinationCoordinate {
  final double latitude;
  final double longitude;

  const TaskDestinationCoordinate({
    required this.latitude,
    required this.longitude,
  });
}

class EnvironmentTaskService {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  late final ApiClient apiClient = ApiClient(storage: storage);

  Future<List<EnvironmentCleanupTask>> fetchMyTasks() async {
    final response = await apiClient.get('/api/environment/tasks/my');
    if (response.statusCode != 200) {
      throw Exception('Không thể tải danh sách công việc môi trường.');
    }

    final List<dynamic> data = apiClient.decodeUtf8Json(response);
    return data
        .map(
          (item) =>
              EnvironmentCleanupTask.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<TaskDestinationCoordinate?> fetchTaskDestinationByReportId(
    int reportId,
  ) async {
    final response = await apiClient.get('/api/public/reports');
    if (response.statusCode != 200) {
      return null;
    }

    final decoded = apiClient.decodeUtf8Json(response);
    if (decoded is! List) {
      return null;
    }

    for (final item in decoded) {
      if (item is! Map<String, dynamic>) continue;

      final id = _toInt(item['reportId']);
      if (id != reportId) continue;

      final lat = _toDouble(item['gpsLat']);
      final long = _toDouble(item['gpsLong']);
      if (lat == null || long == null) {
        return null;
      }

      return TaskDestinationCoordinate(latitude: lat, longitude: long);
    }

    return null;
  }

  Future<void> completeTask({
    required int taskId,
    required String afterImageUrl,
    required String completionNote,
    required String gpsLat,
    required String gpsLong,
  }) async {
    final response = await apiClient
        .put('/api/environment/tasks/$taskId/complete', {
          'afterImageUrl': afterImageUrl,
          'completionNote': completionNote,
          'gpsLat': gpsLat,
          'gpsLong': gpsLong,
        });

    if (response.statusCode != 200) {
      final decoded = apiClient.decodeUtf8Json(response);
      final message = decoded is Map<String, dynamic>
          ? decoded['message']
          : null;
      throw Exception(message?.toString() ?? 'Cập nhật hoàn tất thất bại.');
    }
  }

  Future<String> uploadCompletionImage(String imagePath) async {
    final streamed = await apiClient.postMultipart(
      '/api/environment/tasks/upload-image',
      {},
      {'image': imagePath},
    );

    final response = await http.Response.fromStream(streamed);
    final decoded = apiClient.decodeUtf8Json(response);

    if (response.statusCode != 200) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString()
          : null;
      throw Exception(message ?? 'Upload ảnh thất bại.');
    }

    if (decoded is! Map<String, dynamic> || decoded['imageUrl'] == null) {
      throw Exception('Không nhận được URL ảnh sau khi upload.');
    }

    return decoded['imageUrl'].toString();
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
