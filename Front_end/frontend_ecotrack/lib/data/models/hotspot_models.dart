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
      clusterId: (json['cluster_id'] ?? 0) as int,
      centerLat: (json['center_lat'] ?? 0.0).toDouble(),
      centerLng: (json['center_lng'] ?? 0.0).toDouble(),
      radiusKm: (json['radius_km'] ?? 0.0).toDouble(),
      reportCount: (json['report_count'] ?? 0) as int,
      riskScore: json['risk_score'] != null
          ? (json['risk_score'] as num).toDouble()
          : null,
      predictedCount7d: json['predicted_count_7d'] as int?,
    );
  }
}

class PredictedHeatmapPoint {
  final double lat;
  final double lng;
  final double intensity;
  final int predictedCount7d;

  PredictedHeatmapPoint({
    required this.lat,
    required this.lng,
    required this.intensity,
    required this.predictedCount7d,
  });

  factory PredictedHeatmapPoint.fromJson(Map<String, dynamic> json) {
    return PredictedHeatmapPoint(
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
      intensity: (json['intensity'] ?? 0.0).toDouble(),
      predictedCount7d: (json['predicted_count_7d'] ?? 0) as int,
    );
  }
}

class ClusterHotspotApiResponse {
  final bool success;
  final List<HotspotZone> hotspots;

  ClusterHotspotApiResponse({required this.success, required this.hotspots});

  factory ClusterHotspotApiResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> raw = (json['hotspots'] as List?) ?? const [];
    return ClusterHotspotApiResponse(
      success: (json['success'] ?? false) as bool,
      hotspots: raw
          .whereType<Map<String, dynamic>>()
          .map(HotspotZone.fromJson)
          .toList(),
    );
  }
}

class PredictHotspotApiResponse {
  final bool success;
  final List<HotspotZone> predictedHotspots7Days;
  final List<PredictedHeatmapPoint> heatmapPoints;

  PredictHotspotApiResponse({
    required this.success,
    required this.predictedHotspots7Days,
    required this.heatmapPoints,
  });

  factory PredictHotspotApiResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawHotspots =
        (json['predicted_hotspots_7_days'] as List?) ?? const [];
    final List<dynamic> rawHeatmap =
        (json['heatmap_points'] as List?) ?? const [];

    return PredictHotspotApiResponse(
      success: (json['success'] ?? false) as bool,
      predictedHotspots7Days: rawHotspots
          .whereType<Map<String, dynamic>>()
          .map(HotspotZone.fromJson)
          .toList(),
      heatmapPoints: rawHeatmap
          .whereType<Map<String, dynamic>>()
          .map(PredictedHeatmapPoint.fromJson)
          .toList(),
    );
  }
}
