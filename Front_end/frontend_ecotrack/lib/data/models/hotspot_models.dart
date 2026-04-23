class HotspotZone {
  final int clusterId;
  final double centerLat;
  final double centerLng;
  final double radiusKm;
  final int reportCount;
  final double? riskScore;
  final int? predictedCount7d;

  HotspotZone({
    required this.clusterId,
    required this.centerLat,
    required this.centerLng,
    required this.radiusKm,
    required this.reportCount,
    this.riskScore,
    this.predictedCount7d,
  });

  factory HotspotZone.fromJson(Map<String, dynamic> json) {
    return HotspotZone(
      clusterId: _parseInt(json['cluster_id'] ?? json['clusterId']) ?? 0,
      centerLat: _parseDouble(json['center_lat'] ?? json['centerLat']) ?? 0.0,
      centerLng: _parseDouble(json['center_lng'] ?? json['centerLng']) ?? 0.0,
      radiusKm: _parseDouble(json['radius_km'] ?? json['radiusKm']) ?? 0.0,
      reportCount: _parseInt(json['report_count'] ?? json['reportCount']) ?? 0,
      riskScore: _parseDouble(json['risk_score'] ?? json['riskScore']),
      predictedCount7d: _parseInt(
        json['predicted_count_7d'] ?? json['predictedCount7d'],
      ),
    );
  }
}

class PredictedHeatmapPoint {
  final double lat;
  final double lng;
  final double intensity;
  final int predictedCount7d;
  final int reportCount;

  PredictedHeatmapPoint({
    required this.lat,
    required this.lng,
    required this.intensity,
    required this.predictedCount7d,
    this.reportCount = 0,
  });

  factory PredictedHeatmapPoint.fromJson(Map<String, dynamic> json) {
    return PredictedHeatmapPoint(
      lat: _parseDouble(json['lat']) ?? 0.0,
      lng: _parseDouble(json['lng']) ?? 0.0,
      intensity: _parseDouble(json['intensity']) ?? 0.0,
      predictedCount7d:
          _parseInt(json['predicted_count_7d'] ?? json['predictedCount7d']) ??
          0,
      reportCount: _parseInt(json['report_count'] ?? json['reportCount']) ?? 0,
    );
  }
}

class ClusterHotspotApiResponse {
  final bool success;
  final List<HotspotZone> hotspots;
  final String? errorMessage; // ✅ NEW: Error message if request fails
  final double? confidenceScore; // ✅ NEW: Confidence score of the prediction

  ClusterHotspotApiResponse({
    required this.success,
    required this.hotspots,
    this.errorMessage,
    this.confidenceScore,
  });

  factory ClusterHotspotApiResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> raw =
        ((json['hotspots'] ?? json['data']) as List?) ?? const [];
    return ClusterHotspotApiResponse(
      success: _parseBool(json['success']) ?? false,
      hotspots: raw
          .whereType<Map<String, dynamic>>()
          .map(HotspotZone.fromJson)
          .toList(),
      errorMessage: json['error_message'] ?? json['errorMessage'],
      confidenceScore: _parseDouble(
        json['confidence_score'] ?? json['confidenceScore'],
      ),
    );
  }
}

class PredictHotspotApiResponse {
  final bool success;
  final List<HotspotZone> predictedHotspots7Days;
  final List<PredictedHeatmapPoint> heatmapPoints;
  final String? errorMessage; // ✅ NEW: Error message if prediction fails
  final double? confidenceScore; // ✅ NEW: Confidence score of the prediction

  PredictHotspotApiResponse({
    required this.success,
    required this.predictedHotspots7Days,
    required this.heatmapPoints,
    this.errorMessage,
    this.confidenceScore,
  });

  factory PredictHotspotApiResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawHotspots =
        ((json['predicted_hotspots_7_days'] ?? json['predictedHotspots7Days'])
            as List?) ??
        const [];
    final List<dynamic> rawHeatmap =
        ((json['heatmap_points'] ?? json['heatmapPoints']) as List?) ??
        const [];

    return PredictHotspotApiResponse(
      success: _parseBool(json['success']) ?? false,
      predictedHotspots7Days: rawHotspots
          .whereType<Map<String, dynamic>>()
          .map(HotspotZone.fromJson)
          .toList(),
      heatmapPoints: rawHeatmap
          .whereType<Map<String, dynamic>>()
          .map(PredictedHeatmapPoint.fromJson)
          .toList(),
      errorMessage: json['error_message'] ?? json['errorMessage'],
      confidenceScore: _parseDouble(
        json['confidence_score'] ?? json['confidenceScore'],
      ),
    );
  }
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String)
    return int.tryParse(value) ?? double.tryParse(value)?.toInt();
  return null;
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

bool? _parseBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return null;
}
