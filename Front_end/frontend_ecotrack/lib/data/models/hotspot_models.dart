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

  ClusterHotspotApiResponse({required this.success, required this.hotspots});

  factory ClusterHotspotApiResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> raw =
        ((json['hotspots'] ?? json['data']) as List?) ?? const [];
    return ClusterHotspotApiResponse(
      success: _parseBool(json['success']) ?? false,
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
    );
  }
}

class RecyclingSuggestion {
  final String title;
  final List<String> steps;

  RecyclingSuggestion({required this.title, required this.steps});

  factory RecyclingSuggestion.fromJson(Map<String, dynamic> json) {
    return RecyclingSuggestion(
      title: (json['title'] ?? '').toString(),
      steps:
          ((json['steps'] as List?) ?? const [])
              .map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList(),
    );
  }
}

class NearbyHotspot {
  final int clusterId;
  final double centerLat;
  final double centerLng;
  final double radiusKm;
  final int reportCount;
  final double distanceMeters;
  final Map<String, int> categoryCounts;
  final String dominantWasteType;
  final RecyclingSuggestion recyclingSuggestion;

  NearbyHotspot({
    required this.clusterId,
    required this.centerLat,
    required this.centerLng,
    required this.radiusKm,
    required this.reportCount,
    required this.distanceMeters,
    required this.categoryCounts,
    required this.dominantWasteType,
    required this.recyclingSuggestion,
  });

  factory NearbyHotspot.fromJson(Map<String, dynamic> json) {
    final rawCategoryCounts =
        (json['categoryCounts'] ?? json['category_counts']) as Map?;

    return NearbyHotspot(
      clusterId: _parseInt(json['clusterId'] ?? json['cluster_id']) ?? 0,
      centerLat: _parseDouble(json['centerLat'] ?? json['center_lat']) ?? 0.0,
      centerLng: _parseDouble(json['centerLng'] ?? json['center_lng']) ?? 0.0,
      radiusKm: _parseDouble(json['radiusKm'] ?? json['radius_km']) ?? 0.0,
      reportCount: _parseInt(json['reportCount'] ?? json['report_count']) ?? 0,
      distanceMeters:
          _parseDouble(json['distanceMeters'] ?? json['distance_meters']) ??
          0.0,
      categoryCounts: rawCategoryCounts == null
          ? const {}
          : rawCategoryCounts.map(
              (key, value) => MapEntry(key.toString(), _parseInt(value) ?? 0),
            ),
      dominantWasteType: (json['dominantWasteType'] ??
              json['dominant_waste_type'] ??
              'Rác hỗn hợp')
          .toString(),
      recyclingSuggestion: RecyclingSuggestion.fromJson(
        ((json['recyclingSuggestion'] ?? json['recycling_suggestion']) as Map?)
                ?.cast<String, dynamic>() ??
            const {},
      ),
    );
  }
}

class NearbyHotspotApiResponse {
  final bool success;
  final bool alert;
  final NearbyHotspot? nearestHotspot;
  final List<NearbyHotspot> hotspots;

  NearbyHotspotApiResponse({
    required this.success,
    required this.alert,
    required this.nearestHotspot,
    required this.hotspots,
  });

  factory NearbyHotspotApiResponse.fromJson(Map<String, dynamic> json) {
    final nearestRaw = json['nearestHotspot'] ?? json['nearest_hotspot'];
    final List<dynamic> rawHotspots =
        ((json['hotspots'] ?? json['data']) as List?) ?? const [];

    return NearbyHotspotApiResponse(
      success: _parseBool(json['success']) ?? false,
      alert: _parseBool(json['alert']) ?? false,
      nearestHotspot: nearestRaw is Map
          ? NearbyHotspot.fromJson(nearestRaw.cast<String, dynamic>())
          : null,
      hotspots: rawHotspots
          .whereType<Map<String, dynamic>>()
          .map(NearbyHotspot.fromJson)
          .toList(),
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
