class ClassificationHistoryListResponse {
  final bool success;
  final String code;
  final String message;
  final List<ClassificationHistoryListItem>? data;

  ClassificationHistoryListResponse({
    required this.success,
    required this.code,
    required this.message,
    this.data,
  });

  factory ClassificationHistoryListResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClassificationHistoryListResponse(
      success: json['success'] ?? false,
      code: json['code'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] != null
          ? (json['data'] as List)
                .map(
                  (item) => ClassificationHistoryListItem.fromJson(
                    item as Map<String, dynamic>,
                  ),
                )
                .toList()
          : null,
    );
  }
}

class ClassificationHistoryListItem {
  final int historyId;
  final bool trashDetected;
  final double overallConfidence;
  final int totalObjectsDetected;
  final String originalImageUrl;
  final String createdAt;

  ClassificationHistoryListItem({
    required this.historyId,
    required this.trashDetected,
    required this.overallConfidence,
    required this.totalObjectsDetected,
    required this.originalImageUrl,
    required this.createdAt,
  });

  factory ClassificationHistoryListItem.fromJson(Map<String, dynamic> json) {
    return ClassificationHistoryListItem(
      historyId: json['historyId'] ?? json['history_id'] ?? 0,
      trashDetected: json['trashDetected'] ?? json['trash_detected'] ?? false,
      overallConfidence:
          (json['overallConfidence'] ?? json['overall_confidence'] ?? 0.0)
              .toDouble(),
      totalObjectsDetected:
          json['totalObjectsDetected'] ?? json['total_objects_detected'] ?? 0,
      originalImageUrl:
          json['originalImageUrl'] ?? json['original_image_url'] ?? '',
      createdAt: json['createdAt'] ?? json['created_at'] ?? '',
    );
  }
}

class ClassificationHistoryDetailResponse {
  final bool success;
  final String code;
  final String message;
  final ClassificationHistoryDetail? data;

  ClassificationHistoryDetailResponse({
    required this.success,
    required this.code,
    required this.message,
    this.data,
  });

  factory ClassificationHistoryDetailResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClassificationHistoryDetailResponse(
      success: json['success'] ?? false,
      code: json['code'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] != null
          ? ClassificationHistoryDetail.fromJson(
              json['data'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class ClassificationHistoryDetail {
  final int historyId;
  final bool trashDetected;
  final double overallConfidence;
  final int totalObjectsDetected;
  final List<String> wasteTypes;
  final String wasteTypesJson;
  final List<Map<String, dynamic>> detections;
  final String originalImageUrl;
  final String createdAt;

  ClassificationHistoryDetail({
    required this.historyId,
    required this.trashDetected,
    required this.overallConfidence,
    required this.totalObjectsDetected,
    required this.wasteTypes,
    required this.wasteTypesJson,
    required this.detections,
    required this.originalImageUrl,
    required this.createdAt,
  });

  factory ClassificationHistoryDetail.fromJson(Map<String, dynamic> json) {
    List<String> wasteTypes = [];
    if (json['wasteTypes'] != null) {
      wasteTypes = List<String>.from(json['wasteTypes'] as List);
    } else if (json['waste_types'] != null) {
      wasteTypes = List<String>.from(json['waste_types'] as List);
    }

    List<Map<String, dynamic>> detections = [];
    if (json['detections'] != null) {
      detections = List<Map<String, dynamic>>.from(json['detections'] as List);
    }

    final wasteTypesJson =
        json['wasteTypesJson'] ?? json['waste_types_json'] ?? '';

    return ClassificationHistoryDetail(
      historyId: json['historyId'] ?? json['history_id'] ?? 0,
      trashDetected: json['trashDetected'] ?? json['trash_detected'] ?? false,
      overallConfidence:
          (json['overallConfidence'] ?? json['overall_confidence'] ?? 0.0)
              .toDouble(),
      totalObjectsDetected:
          json['totalObjectsDetected'] ?? json['total_objects_detected'] ?? 0,
      wasteTypes: wasteTypes,
      wasteTypesJson: wasteTypesJson,
      detections: detections,
      originalImageUrl:
          json['originalImageUrl'] ?? json['original_image_url'] ?? '',
      createdAt: json['createdAt'] ?? json['created_at'] ?? '',
    );
  }
}
