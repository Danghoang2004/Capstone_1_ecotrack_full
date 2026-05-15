class Report {
  final int reportId;
  final String title;
  final String description;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final String status;
  final DateTime createdAt;
  final String category;
  final bool? aiVerified;
  final double? aiConfidence;
  final String? aiAnalysisJson; // JSON string chứa chi tiết loại rác
  final String? aiWasteType;
  final double? aiFinalWasteScore;
  final double? aiWasteContextScore;
  final double? aiWasteAreaRatio;
  final int? aiObjectCount;
  final int? aiSeverityScore;
  final String? aiPollutionLevel;
  final String? aiSeverityDescription;
  final String? aiRecommendation;
  final String? aiDecision;
  final bool? aiNeedManualReview;
  final String? aiErrorMessage;
  final String? aiFalsePositiveReason;
  final int reportCount;
  final List<ReportReporter> reporters;

  Report({
    required this.reportId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
    required this.category,
    this.aiVerified,
    this.aiConfidence,
    this.aiAnalysisJson,
    this.aiWasteType,
    this.aiFinalWasteScore,
    this.aiWasteContextScore,
    this.aiWasteAreaRatio,
    this.aiObjectCount,
    this.aiSeverityScore,
    this.aiPollutionLevel,
    this.aiSeverityDescription,
    this.aiRecommendation,
    this.aiDecision,
    this.aiNeedManualReview,
    this.aiErrorMessage,
    this.aiFalsePositiveReason,
    this.reportCount = 1,
    this.reporters = const [],
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      reportId: json['reportId'] ?? 0,
      title: json['title'] ?? 'Không có tiêu đề',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      latitude: (json['gpsLat'] ?? 0.0)
          .toDouble(), // Sửa theo tên cột DB Spring Boot
      longitude: (json['gpsLong'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'UNKNOWN',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      category: json['category'] ?? 'Khác',
      aiVerified: json['aiVerified'],
      aiConfidence: (json['aiConfidence'] ?? 0.0).toDouble(),
      aiAnalysisJson: json['aiAnalysisJson'],
      aiWasteType: json['aiWasteType'],
      aiFinalWasteScore: (json['aiFinalWasteScore'] ?? 0.0).toDouble(),
      aiWasteContextScore: (json['aiWasteContextScore'] ?? 0.0).toDouble(),
      aiWasteAreaRatio: (json['aiWasteAreaRatio'] ?? 0.0).toDouble(),
      aiObjectCount: json['aiObjectCount'],
      aiSeverityScore: json['aiSeverityScore'],
      aiPollutionLevel: json['aiPollutionLevel'],
      aiSeverityDescription: json['aiSeverityDescription'],
      aiRecommendation: json['aiRecommendation'],
      aiDecision: json['aiDecision'],
      aiNeedManualReview: json['aiNeedManualReview'],
      aiErrorMessage: json['aiErrorMessage'],
      aiFalsePositiveReason: json['aiFalsePositiveReason'],
      reportCount: json['reportCount'] ?? 1,
      reporters: (json['reporters'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ReportReporter.fromJson)
          .toList(),
    );
  }
}

class ReportReporter {
  final int userId;
  final String username;
  final String email;
  final int reportCount;
  final DateTime? latestReportedAt;

  const ReportReporter({
    required this.userId,
    required this.username,
    required this.email,
    required this.reportCount,
    required this.latestReportedAt,
  });

  factory ReportReporter.fromJson(Map<String, dynamic> json) {
    final latest = json['latestReportedAt'];
    return ReportReporter(
      userId: json['userId'] ?? 0,
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      reportCount: json['reportCount'] ?? 1,
      latestReportedAt: latest is String && latest.isNotEmpty
          ? DateTime.tryParse(latest)
          : null,
    );
  }
}
