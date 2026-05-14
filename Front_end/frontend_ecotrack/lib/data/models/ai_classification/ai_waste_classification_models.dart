class AiWasteClassificationResponse {
  final bool success;
  final String code;
  final String message;
  final AiWasteClassificationData? data;

  const AiWasteClassificationResponse({
    required this.success,
    required this.code,
    required this.message,
    this.data,
  });

  factory AiWasteClassificationResponse.fromJson(Map<String, dynamic> json) {
    return AiWasteClassificationResponse(
      success: json['success'] == true,
      code: (json['code'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      data: json['data'] is Map<String, dynamic>
          ? AiWasteClassificationData.fromJson(
              json['data'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class AiWasteClassificationData {
  final bool trashDetected;
  final double overallConfidence;
  final int totalObjectsDetected;
  final Map<String, double> wasteTypes;
  final List<AiWasteDetection> detections;
  final String? analyzedImagePath;

  const AiWasteClassificationData({
    required this.trashDetected,
    required this.overallConfidence,
    required this.totalObjectsDetected,
    required this.wasteTypes,
    required this.detections,
    required this.analyzedImagePath,
  });

  factory AiWasteClassificationData.fromJson(Map<String, dynamic> json) {
    final rawWasteTypes =
        (json['wasteTypes'] ?? json['waste_types']) as Map<String, dynamic>?;
    final wasteTypes = <String, double>{};

    if (rawWasteTypes != null) {
      for (final entry in rawWasteTypes.entries) {
        final value = entry.value;
        if (value is num) {
          wasteTypes[entry.key] = value.toDouble();
        }
      }
    }

    final rawDetections = json['detections'] as List<dynamic>? ?? <dynamic>[];

    return AiWasteClassificationData(
      trashDetected:
          json['trashDetected'] == true ||
          json['is_waste'] == true ||
          json['is_trash'] == true,
      overallConfidence:
          ((json['overallConfidence'] ?? json['overall_confidence']) as num?)
              ?.toDouble() ??
          0.0,
      totalObjectsDetected:
          ((json['totalObjectsDetected'] ?? json['total_objects_detected'])
                  as num?)
              ?.toInt() ??
          0,
      wasteTypes: wasteTypes,
      detections: rawDetections
          .whereType<Map<String, dynamic>>()
          .map(AiWasteDetection.fromJson)
          .toList(),
      analyzedImagePath: (json['analyzedImagePath'] ?? json['output_image'])
          ?.toString(),
    );
  }
}

class AiWasteDetection {
  final String classNameVietnamese;
  final String classNameRaw;
  final double confidence;

  const AiWasteDetection({
    required this.classNameVietnamese,
    required this.classNameRaw,
    required this.confidence,
  });

  factory AiWasteDetection.fromJson(Map<String, dynamic> json) {
    return AiWasteDetection(
      classNameVietnamese:
          (json['classNameVietnamese'] ?? json['class_name_vietnamese'] ?? '')
              .toString(),
      classNameRaw: (json['classNameRaw'] ?? json['class_name_raw'] ?? '')
          .toString(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
