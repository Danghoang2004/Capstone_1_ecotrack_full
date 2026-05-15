import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

class RecycleStepDto {
  final int? stepId;
  final int stepOrder;
  final String stepTitle;
  final String stepDescription;
  final String? instructionImageUrl;
  final String? instructionVideoUrl;

  RecycleStepDto({
    this.stepId,
    required this.stepOrder,
    required this.stepTitle,
    required this.stepDescription,
    this.instructionImageUrl,
    this.instructionVideoUrl,
  });

  factory RecycleStepDto.fromJson(Map<String, dynamic> json) => RecycleStepDto(
        stepId: json['stepId'],
        stepOrder: json['stepOrder'] ?? 0,
        stepTitle: json['stepTitle'] ?? '',
        stepDescription: json['stepDescription'] ?? '',
        instructionImageUrl: json['instructionImageUrl'],
        instructionVideoUrl: json['instructionVideoUrl'],
      );
}

class RecycleGuideDto {
  final int guideId;
  final String wasteTypeKey;
  final String wasteTypeLabel;
  final String name;
  final String description;
  final String? imageUrl;
  final String? difficultyLevel;
  final int? estimatedTimeMinutes;
  final String? materialsNeeded;
  final bool isActive;
  final int stepCount;
  final List<RecycleStepDto> steps;

  RecycleGuideDto({
    required this.guideId,
    required this.wasteTypeKey,
    required this.wasteTypeLabel,
    required this.name,
    required this.description,
    this.imageUrl,
    this.difficultyLevel,
    this.estimatedTimeMinutes,
    this.materialsNeeded,
    this.isActive = true,
    this.stepCount = 0,
    this.steps = const [],
  });

  factory RecycleGuideDto.fromJson(Map<String, dynamic> json) => RecycleGuideDto(
        guideId: json['guideId'] ?? 0,
        wasteTypeKey: json['wasteTypeKey'] ?? '',
        wasteTypeLabel: json['wasteTypeLabel'] ?? '',
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        imageUrl: json['imageUrl'],
        difficultyLevel: json['difficultyLevel'],
        estimatedTimeMinutes: json['estimatedTimeMinutes'],
        materialsNeeded: json['materialsNeeded'],
        isActive: json['isActive'] ?? true,
        stepCount: json['stepCount'] ?? 0,
        steps: ((json['steps'] as List<dynamic>?) ?? const [])
            .map((e) => RecycleStepDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class AdminRecycleService {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  late final ApiClient apiClient = ApiClient(storage: storage);

  AdminRecycleService._private();
  static final AdminRecycleService instance = AdminRecycleService._private();

  final _base = '/api/admin/recycle';

  Future<List<RecycleGuideDto>> listGuides() async {
    final res = await apiClient.get('$_base/guides');
    final body = apiClient.decodeUtf8Json(res) as List<dynamic>;
    return body.map((e) => RecycleGuideDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<RecycleGuideDto> createGuide(Map<String, dynamic> payload) async {
    final res = await apiClient.post('$_base/guides', payload);
    final body = apiClient.decodeUtf8Json(res) as Map<String, dynamic>;
    return RecycleGuideDto.fromJson(body);
  }

  Future<RecycleGuideDto> updateGuide(int id, Map<String, dynamic> payload) async {
    final res = await apiClient.put('$_base/guides/$id', payload);
    final body = apiClient.decodeUtf8Json(res) as Map<String, dynamic>;
    return RecycleGuideDto.fromJson(body);
  }

  Future<void> deleteGuide(int id) async {
    await apiClient.delete('$_base/guides/$id');
  }

  Future<String> uploadMedia({
    required Uint8List bytes,
    required String fileName,
    String folder = 'ecotrack/recycle',
  }) async {
    final streamed = await apiClient.postMultipartBytes(
      '$_base/upload-media?folder=$folder',
      {},
      {'file': bytes},
      fileName,
    );

    final response = await http.Response.fromStream(streamed);
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
      return (body['url'] ?? '').toString();
    }
    throw Exception((body['message'] ?? 'Upload thất bại').toString());
  }
}
