import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/data/models/hotspot_models.dart';

class HotspotService {
  final ApiClient _apiClient = ApiClient(storage: const FlutterSecureStorage());

  Future<ClusterHotspotApiResponse> fetchClusterInArea({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    double epsKm = 0.5,
    int minSamples = 2,
  }) async {
    final path =
        '/api/public/hotspots/cluster/area?minLat=$minLat&maxLat=$maxLat&minLng=$minLng&maxLng=$maxLng&eps_km=$epsKm&min_samples=$minSamples';

    final response = await _apiClient.get(path);
    if (response.statusCode != 200) {
      return ClusterHotspotApiResponse(success: false, hotspots: []);
    }

    final json = _apiClient.decodeUtf8Json(response) as Map<String, dynamic>;
    return ClusterHotspotApiResponse.fromJson(json);
  }

  Future<PredictHotspotApiResponse> fetchPredictionInArea({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    int horizonDays = 7,
    int gridSizeM = 200,
    double topPercent = 0.1,
    int minPredictedCount = 3,
    double dbscanEpsKm = 0.35,
    int dbscanMinSamples = 2,
  }) async {
    final path =
        '/api/public/hotspots/predict/area?minLat=$minLat&maxLat=$maxLat&minLng=$minLng&maxLng=$maxLng&horizonDays=$horizonDays&gridSizeM=$gridSizeM&topPercent=$topPercent&minPredictedCount=$minPredictedCount&dbscanEpsKm=$dbscanEpsKm&dbscanMinSamples=$dbscanMinSamples';

    final response = await _apiClient.get(path);
    if (response.statusCode != 200) {
      return PredictHotspotApiResponse(
        success: false,
        predictedHotspots7Days: [],
        heatmapPoints: [],
      );
    }

    final json = _apiClient.decodeUtf8Json(response) as Map<String, dynamic>;
    return PredictHotspotApiResponse.fromJson(json);
  }

  Future<ClusterHotspotApiResponse> fetchAdminClusterInArea({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    double epsKm = 0.5,
    int minSamples = 2,
  }) async {
    final path =
        '/api/admin/hotspots/cluster/area?minLat=$minLat&maxLat=$maxLat&minLng=$minLng&maxLng=$maxLng&eps_km=$epsKm&min_samples=$minSamples';

    final response = await _apiClient.get(path);
    if (response.statusCode != 200) {
      return ClusterHotspotApiResponse(success: false, hotspots: []);
    }

    final json = _apiClient.decodeUtf8Json(response) as Map<String, dynamic>;
    return ClusterHotspotApiResponse.fromJson(json);
  }

  Future<PredictHotspotApiResponse> fetchAdminPredictionInArea({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    int horizonDays = 7,
    int gridSizeM = 200,
    double topPercent = 0.1,
    int minPredictedCount = 3,
    double dbscanEpsKm = 0.35,
    int dbscanMinSamples = 2,
  }) async {
    final path =
        '/api/admin/hotspots/predict/area?minLat=$minLat&maxLat=$maxLat&minLng=$minLng&maxLng=$maxLng&horizonDays=$horizonDays&gridSizeM=$gridSizeM&topPercent=$topPercent&minPredictedCount=$minPredictedCount&dbscanEpsKm=$dbscanEpsKm&dbscanMinSamples=$dbscanMinSamples';

    final response = await _apiClient.get(path);
    if (response.statusCode != 200) {
      return PredictHotspotApiResponse(
        success: false,
        predictedHotspots7Days: [],
        heatmapPoints: [],
      );
    }

    final json = _apiClient.decodeUtf8Json(response) as Map<String, dynamic>;
    return PredictHotspotApiResponse.fromJson(json);
  }
}
