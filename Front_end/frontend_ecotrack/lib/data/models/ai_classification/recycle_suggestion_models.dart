import 'dart:convert';

class RecycleSuggestionListResponse {
  final bool success;
  final String code;
  final String message;
  final List<RecycleSuggestionListItem> data;

  const RecycleSuggestionListResponse({
    required this.success,
    required this.code,
    required this.message,
    required this.data,
  });

  factory RecycleSuggestionListResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] as List<dynamic>? ?? const [];

    return RecycleSuggestionListResponse(
      success: json['success'] == true,
      code: (json['code'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      data: rawData
          .whereType<Map<String, dynamic>>()
          .map(RecycleSuggestionListItem.fromJson)
          .toList(),
    );
  }
}

class RecycleSuggestionListItem {
  final int suggestionId;
  final String wasteTypeKey;
  final String wasteTypeLabel;
  final String title;
  final String shortDescription;
  final String recycleImageUrl;
  final String difficultyLevel;
  final int? estimatedTimeMinutes;

  const RecycleSuggestionListItem({
    required this.suggestionId,
    required this.wasteTypeKey,
    required this.wasteTypeLabel,
    required this.title,
    required this.shortDescription,
    required this.recycleImageUrl,
    required this.difficultyLevel,
    required this.estimatedTimeMinutes,
  });

  factory RecycleSuggestionListItem.fromJson(Map<String, dynamic> json) {
    return RecycleSuggestionListItem(
      suggestionId:
          ((json['suggestionId'] ?? json['suggestion_id']) as num?)?.toInt() ??
          0,
      wasteTypeKey: (json['wasteTypeKey'] ?? json['waste_type_key'] ?? '')
          .toString(),
      wasteTypeLabel: (json['wasteTypeLabel'] ?? json['waste_type_label'] ?? '')
          .toString(),
      title: (json['title'] ?? '').toString(),
      shortDescription:
          (json['shortDescription'] ?? json['short_description'] ?? '')
              .toString(),
      recycleImageUrl:
          (json['recycleImageUrl'] ?? json['recycle_image_url'] ?? '')
              .toString(),
      difficultyLevel:
          (json['difficultyLevel'] ?? json['difficulty_level'] ?? '')
              .toString(),
      estimatedTimeMinutes:
          ((json['estimatedTimeMinutes'] ?? json['estimated_time_minutes'])
                  as num?)
              ?.toInt(),
    );
  }
}

class RecycleSuggestionDetailResponse {
  final bool success;
  final String code;
  final String message;
  final RecycleSuggestionDetail? data;

  const RecycleSuggestionDetailResponse({
    required this.success,
    required this.code,
    required this.message,
    required this.data,
  });

  factory RecycleSuggestionDetailResponse.fromJson(Map<String, dynamic> json) {
    return RecycleSuggestionDetailResponse(
      success: json['success'] == true,
      code: (json['code'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      data: json['data'] is Map<String, dynamic>
          ? RecycleSuggestionDetail.fromJson(
              json['data'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class RecycleSuggestionDetail {
  final int suggestionId;
  final String wasteTypeLabel;
  final String title;
  final String shortDescription;
  final String recycleImageUrl;
  final String difficultyLevel;
  final int? estimatedTimeMinutes;
  final List<String> materialsNeeded;
  final List<RecycleSuggestionStep> steps;

  const RecycleSuggestionDetail({
    required this.suggestionId,
    required this.wasteTypeLabel,
    required this.title,
    required this.shortDescription,
    required this.recycleImageUrl,
    required this.difficultyLevel,
    required this.estimatedTimeMinutes,
    required this.materialsNeeded,
    required this.steps,
  });

  factory RecycleSuggestionDetail.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['steps'] as List<dynamic>? ?? const [];
    final rawMaterials = json['materialsNeeded'] ?? json['materials_needed'];

    List<String> materials = const [];
    if (rawMaterials is List) {
      materials = rawMaterials.map((e) => e.toString()).toList();
    } else if (rawMaterials is String && rawMaterials.trim().isNotEmpty) {
      try {
        final parsed = jsonDecode(rawMaterials);
        if (parsed is List) {
          materials = parsed.map((e) => e.toString()).toList();
        } else {
          materials = [rawMaterials];
        }
      } catch (_) {
        materials = rawMaterials
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }

    return RecycleSuggestionDetail(
      suggestionId:
          ((json['suggestionId'] ?? json['suggestion_id']) as num?)?.toInt() ??
          0,
      wasteTypeLabel: (json['wasteTypeLabel'] ?? json['waste_type_label'] ?? '')
          .toString(),
      title: (json['title'] ?? '').toString(),
      shortDescription:
          (json['shortDescription'] ?? json['short_description'] ?? '')
              .toString(),
      recycleImageUrl:
          (json['recycleImageUrl'] ?? json['recycle_image_url'] ?? '')
              .toString(),
      difficultyLevel:
          (json['difficultyLevel'] ?? json['difficulty_level'] ?? '')
              .toString(),
      estimatedTimeMinutes:
          ((json['estimatedTimeMinutes'] ?? json['estimated_time_minutes'])
                  as num?)
              ?.toInt(),
      materialsNeeded: materials,
      steps: rawSteps
          .whereType<Map<String, dynamic>>()
          .map(RecycleSuggestionStep.fromJson)
          .toList(),
    );
  }
}

class RecycleSuggestionStep {
  final int stepOrder;
  final String stepTitle;
  final String stepDescription;
  final String? instructionImageUrl;
  final String? instructionVideoUrl;

  const RecycleSuggestionStep({
    required this.stepOrder,
    required this.stepTitle,
    required this.stepDescription,
    required this.instructionImageUrl,
    required this.instructionVideoUrl,
  });

  factory RecycleSuggestionStep.fromJson(Map<String, dynamic> json) {
    return RecycleSuggestionStep(
      stepOrder:
          ((json['stepOrder'] ?? json['step_order']) as num?)?.toInt() ?? 0,
      stepTitle: (json['stepTitle'] ?? json['step_title'] ?? '').toString(),
      stepDescription:
          (json['stepDescription'] ?? json['step_description'] ?? '')
              .toString(),
      instructionImageUrl:
          (json['instructionImageUrl'] ?? json['instruction_image_url'])
              ?.toString(),
      instructionVideoUrl:
          (json['instructionVideoUrl'] ?? json['instruction_video_url'])
              ?.toString(),
    );
  }
}
