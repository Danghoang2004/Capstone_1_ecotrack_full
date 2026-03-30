import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:frontend_ecotrack/core/services/hotspot_service.dart';
import 'package:frontend_ecotrack/data/models/Report.dart';
import 'package:frontend_ecotrack/data/models/hotspot_models.dart';
import 'package:latlong2/latlong.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class MapPage extends StatefulWidget {
  final bool hideAppBar;

  const MapPage({super.key, this.hideAppBar = false});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  LatLng _center = LatLng(16.0471, 108.2068);
  double _currentZoom = 14.0;

  final ApiClient apiClient = ApiClient(storage: const FlutterSecureStorage());
  final HotspotService _hotspotService = HotspotService();

  List<Report> _reports = [];
  // Biến lưu trữ báo cáo đã gộp theo tọa độ
  Map<String, List<Report>> _groupedReports = {};

  Timer? _timer;
  Timer? _hotspotDebounce;
  List<LatLng> _routePoints = [];
  bool _isRouting = false;
  bool _isLoadingHotspots = false;
  bool _isHeatmapMode = false;
  LatLng? _myLocation;
  List<PredictedHeatmapPoint> _observedHeatmapPoints = [];
  List<PredictedHeatmapPoint> _predictedHeatmapPoints = [];
  StreamSubscription<Position>? _positionStreamSubscription;

  void _startReportsPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _fetchReports(),
    );
  }

  void _stopReportsPolling() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void initState() {
    super.initState();
    _fetchReports();
    _startReportsPolling();
    _startLiveTracking();
  }

  @override
  void deactivate() {
    _stopReportsPolling();
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _startReportsPolling();
  }

  @override
  void dispose() {
    _stopReportsPolling();
    _hotspotDebounce?.cancel();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  void _onMapPositionChanged(MapPosition position, bool hasGesture) {
    _center = position.center ?? _center;
    _currentZoom = position.zoom ?? _currentZoom;

    if (!_isHeatmapMode) return;

    _hotspotDebounce?.cancel();
    _hotspotDebounce = Timer(const Duration(milliseconds: 600), () {
      _fetchHotspotsFromViewport(position.bounds);
    });
  }

  Future<void> _fetchHotspotsFromViewport([LatLngBounds? bounds]) async {
    final LatLngBounds? targetBounds = bounds ?? _mapController.bounds;
    if (targetBounds == null || _isLoadingHotspots || !_isHeatmapMode) return;

    _isLoadingHotspots = true;
    try {
      final clusterFuture = _hotspotService.fetchClusterInArea(
        minLat: targetBounds.south,
        maxLat: targetBounds.north,
        minLng: targetBounds.west,
        maxLng: targetBounds.east,
      );

      final predictFuture = _hotspotService.fetchPredictionInArea(
        minLat: targetBounds.south,
        maxLat: targetBounds.north,
        minLng: targetBounds.west,
        maxLng: targetBounds.east,
      );

      final clusterResult = await clusterFuture;
      final predictResult = await predictFuture;

      if (!mounted) return;

      // DEBUG: Log dữ liệu
      debugPrint('Cluster hotspots: ${clusterResult.hotspots.length}');
      debugPrint(
        'Predicted heatmap points: ${predictResult.heatmapPoints.length}',
      );

      setState(() {
        _observedHeatmapPoints = _toObservedHeatmapPoints(
          clusterResult.hotspots,
        );
        _predictedHeatmapPoints = predictResult.heatmapPoints;

        // Fallback: nếu API chưa có hotspot thì dựng heatmap từ báo cáo trong vùng nhìn thấy.
        if (_observedHeatmapPoints.isEmpty && _predictedHeatmapPoints.isEmpty) {
          _observedHeatmapPoints = _buildFallbackHeatmapFromReports(
            targetBounds,
          );
        }
      });
    } catch (e) {
      debugPrint('Lỗi fetch hotspot: $e');
    } finally {
      _isLoadingHotspots = false;
    }
  }

  List<PredictedHeatmapPoint> _buildFallbackHeatmapFromReports(
    LatLngBounds bounds,
  ) {
    final reportsInView = _reports.where((r) {
      if (r.status == 'REJECTED') return false;
      return r.latitude >= bounds.south &&
          r.latitude <= bounds.north &&
          r.longitude >= bounds.west &&
          r.longitude <= bounds.east;
    }).toList();

    if (reportsInView.isEmpty) return [];

    const double cellSize = 0.0035; // ~350-400m
    final Map<String, int> counts = {};
    final Map<String, double> sumLat = {};
    final Map<String, double> sumLng = {};

    for (final r in reportsInView) {
      final int latCell = (r.latitude / cellSize).floor();
      final int lngCell = (r.longitude / cellSize).floor();
      final key = '$latCell:$lngCell';

      counts[key] = (counts[key] ?? 0) + 1;
      sumLat[key] = (sumLat[key] ?? 0) + r.latitude;
      sumLng[key] = (sumLng[key] ?? 0) + r.longitude;
    }

    final int maxCount = counts.values.fold(1, (a, b) => b > a ? b : a);
    return counts.entries.map((e) {
      final key = e.key;
      final count = e.value;
      return PredictedHeatmapPoint(
        lat: (sumLat[key] ?? 0) / count,
        lng: (sumLng[key] ?? 0) / count,
        intensity: (count / maxCount).clamp(0.0, 1.0),
        predictedCount7d: count,
      );
    }).toList();
  }

  List<PredictedHeatmapPoint> _toObservedHeatmapPoints(
    List<HotspotZone> zones,
  ) {
    if (zones.isEmpty) return [];

    final int maxCount = zones
        .map((z) => z.reportCount)
        .fold<int>(1, (acc, value) => value > acc ? value : acc);

    return zones
        .map(
          (z) => PredictedHeatmapPoint(
            lat: z.centerLat,
            lng: z.centerLng,
            intensity: (z.reportCount / maxCount).clamp(0.0, 1.0),
            predictedCount7d: z.reportCount,
          ),
        )
        .toList();
  }

  Color _heatColor(double intensity, {required bool predicted}) {
    final double t = intensity.clamp(0.0, 1.0);
    if (predicted) {
      final Color c1 = const Color(0xFFFFE082);
      final Color c2 = const Color(0xFFFF8A65);
      final Color c3 = const Color(0xFFD32F2F);
      return t < 0.55
          ? Color.lerp(c1, c2, t / 0.55)!
          : Color.lerp(c2, c3, (t - 0.55) / 0.45)!;
    }

    final Color c1 = const Color(0xFFFFF176);
    final Color c2 = const Color(0xFFFFB74D);
    final Color c3 = const Color(0xFFFF5722);
    return t < 0.55
        ? Color.lerp(c1, c2, t / 0.55)!
        : Color.lerp(c2, c3, (t - 0.55) / 0.45)!;
  }

  List<CircleMarker> _buildHeatCircles(
    List<PredictedHeatmapPoint> points, {
    required bool predicted,
  }) {
    final List<CircleMarker> circles = [];
    const List<double> radiusScale = [2.2, 1.8, 1.45, 1.15, 0.85];
    const List<double> opacityScale = [0.06, 0.09, 0.13, 0.19, 0.28];

    for (final point in points) {
      final double t = point.intensity.clamp(0.0, 1.0);
      final double smoothT = Curves.easeOutCubic.transform(t);
      final double baseRadius = predicted
          ? 120 + (smoothT * 200)
          : 110 + (smoothT * 185);

      for (int i = 0; i < radiusScale.length; i++) {
        final double layerT = (smoothT + (i * 0.04)).clamp(0.0, 1.0);
        final Color layerColor = _heatColor(layerT, predicted: predicted);
        circles.add(
          CircleMarker(
            point: LatLng(point.lat, point.lng),
            radius: baseRadius * radiusScale[i],
            useRadiusInMeter: true,
            color: layerColor.withOpacity(
              (opacityScale[i] * (0.8 + smoothT * 0.8)).clamp(0.0, 0.45),
            ),
            borderStrokeWidth: 0,
          ),
        );
      }

      circles.add(
        CircleMarker(
          point: LatLng(point.lat, point.lng),
          radius: baseRadius * 0.55,
          useRadiusInMeter: true,
          color: _heatColor(
            (smoothT + 0.08).clamp(0.0, 1.0),
            predicted: predicted,
          ).withOpacity((0.22 + smoothT * 0.30).clamp(0.0, 0.55)),
          borderStrokeWidth: 0,
        ),
      );
    }
    return circles;
  }

  void _toggleHeatmapMode() {
    final bool toHeatmap = !_isHeatmapMode;
    setState(() => _isHeatmapMode = toHeatmap);
    if (toHeatmap) {
      _fetchHotspotsFromViewport();
    }
  }

  Future<void> _startLiveTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            LatLng newPos = LatLng(position.latitude, position.longitude);
            if (mounted) {
              setState(() {
                _myLocation = newPos;
              });
            }
          },
        );

    Position? firstPos = await Geolocator.getLastKnownPosition();
    if (firstPos != null && _myLocation == null) {
      setState(() {
        _myLocation = LatLng(firstPos.latitude, firstPos.longitude);
        _mapController.move(_myLocation!, 15);
      });
    }
  }

  void _centerOnMe() {
    if (_myLocation != null) {
      _mapController.move(_myLocation!, 16.0);
    }
  }

  void _zoomIn() {
    final double nextZoom = (_currentZoom + 1).clamp(3.0, 19.0);
    _mapController.move(_center, nextZoom);
  }

  void _zoomOut() {
    final double nextZoom = (_currentZoom - 1).clamp(3.0, 19.0);
    _mapController.move(_center, nextZoom);
  }

  void _groupReportsByDistance(List<Report> reports) {
    const double clusterRadius = 40; // mét
    final Distance distance = Distance();

    Map<String, List<Report>> clusters = {};

    for (final report in reports) {
      bool addedToCluster = false;

      final LatLng reportPoint = LatLng(report.latitude, report.longitude);

      for (final entry in clusters.entries) {
        final firstReport = entry.value.first;
        final LatLng clusterCenter = LatLng(
          firstReport.latitude,
          firstReport.longitude,
        );

        final double dist = distance.as(
          LengthUnit.Meter,
          reportPoint,
          clusterCenter,
        );

        if (dist <= clusterRadius) {
          entry.value.add(report);
          addedToCluster = true;
          break;
        }
      }

      if (!addedToCluster) {
        final key = "${report.latitude},${report.longitude}";
        clusters[key] = [report];
      }
    }

    _groupedReports = clusters;
  }

  Future<void> _fetchReports() async {
    final response = await apiClient.get("/api/public/reports");

    if (response.statusCode == 200) {
      final data = apiClient.decodeUtf8Json(response);
      if (mounted) {
        setState(() {
          final List<Report> allReports = (data as List)
              .map((e) => Report.fromJson(e))
              .toList();
          _reports = allReports;
          _groupReportsByDistance(allReports);
        });
      }
    }
  }

  Future<void> _getDirections(double destLat, double destLng) async {
    setState(() {
      _isRouting = true;
      _routePoints = [];
    });

    try {
      Position userPos = await Geolocator.getCurrentPosition();
      setState(() {
        _myLocation = LatLng(userPos.latitude, userPos.longitude);
      });

      final String url =
          "http://router.project-osrm.org/route/v1/driving/${userPos.longitude},${userPos.latitude};$destLng,$destLat?overview=full&geometries=geojson";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> coords =
            data['routes'][0]['geometry']['coordinates'];

        List<LatLng> points = coords.map((point) {
          return LatLng(point[1].toDouble(), point[0].toDouble());
        }).toList();

        setState(() {
          _routePoints = points;
          _isRouting = false;
        });
      } else {
        throw "Lỗi server chỉ đường";
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
      setState(() {
        _isRouting = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.red;
      case 'VERIFIED':
        return Colors.orange;
      case 'CLEANED':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // HÀM HIỂN THỊ CHI TIẾT CÁC BÁO CÁO ĐÃ GỘP
  void _showGroupedReportDetails(List<Report> reports) {
    final String baseUrl = dotenv.env['API_BASE_URL'] ?? "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 10),
              height: 5,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Có ${reports.length} báo cáo tại đây",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blueGrey,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                separatorBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(thickness: 1, color: Colors.black12),
                ),
                itemBuilder: (context, index) {
                  final r = reports[index];
                  String imageUrl = r.imageUrl.startsWith("http")
                      ? r.imageUrl
                      : "$baseUrl${r.imageUrl}";

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              r.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(r.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              r.status,
                              style: TextStyle(
                                color: _getStatusColor(r.status),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Mô tả: ${r.description}",
                        style: const TextStyle(color: Colors.black87),
                      ),
                      if (r.imageUrl.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 150,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _getDirections(r.latitude, r.longitude);
                          },
                          icon: const Icon(
                            Icons.directions,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Chỉ đường đến bãi rác này",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_pin, color: color, size: 18),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Chú thích",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          if (_isHeatmapMode) ...[
            _buildLegendItem(Colors.yellow, "Nhiệt thấp"),
            _buildLegendItem(Colors.orange, "Nhiệt trung bình"),
            _buildLegendItem(Colors.red, "Nhiệt cao / nguy cơ cao"),
          ] else ...[
            _buildLegendItem(Colors.red, "Chờ duyệt"),
            _buildLegendItem(Colors.orange, "Đã xác thực"),
            _buildLegendItem(Colors.green, "Đã dọn dẹp"),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.hideAppBar
          ? null
          : AppBar(
              backgroundColor: Color(0xFF2E7D32),
              title: const Text(
                "Bản đồ báo cáo",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pushNamed(context, '/user_app'),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.my_location, color: Colors.white),
                  onPressed: _centerOnMe,
                ),
              ],
            ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _center,
              zoom: _currentZoom,
              onPositionChanged: _onMapPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ecotrack.frontend_ecotrack',
              ),
              if (_isHeatmapMode && _observedHeatmapPoints.isNotEmpty)
                CircleLayer(
                  circles: _buildHeatCircles(
                    _observedHeatmapPoints,
                    predicted: false,
                  ),
                ),
              if (_isHeatmapMode && _predictedHeatmapPoints.isNotEmpty)
                CircleLayer(
                  circles: _buildHeatCircles(
                    _predictedHeatmapPoints,
                    predicted: true,
                  ),
                ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5.0,
                      color: Colors.blueAccent,
                    ),
                  ],
                ),
              if (_myLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _myLocation!,
                      width: 60,
                      height: 60,
                      builder: (_) => const Icon(
                        Icons.person_pin_circle,
                        color: Colors.blue,
                        size: 45,
                      ),
                    ),
                  ],
                ),
              // VẼ CÁC MARKER ĐÃ ĐƯỢC GỘP
              if (!_isHeatmapMode)
                MarkerLayer(
                  markers: _groupedReports.entries.map((entry) {
                    final reportsAtPos = entry.value;
                    final firstReport = reportsAtPos.first;

                    return Marker(
                      point: LatLng(
                        firstReport.latitude,
                        firstReport.longitude,
                      ),
                      width: 60,
                      height: 60,
                      builder: (_) => GestureDetector(
                        onTap: () => _showGroupedReportDetails(reportsAtPos),
                        child: Stack(
                          children: [
                            Icon(
                              Icons.location_pin,
                              color: _getStatusColor(firstReport.status),
                              size: 45,
                            ),
                            if (reportsAtPos.length > 1)
                              Positioned(
                                right: 5,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    "${reportsAtPos.length}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
          if (_isRouting)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          if (_isLoadingHotspots && _isHeatmapMode)
            const Positioned(
              top: 18,
              left: 18,
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          Positioned(top: 12, right: 10, child: _buildLegend()),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (_routePoints.isNotEmpty)
              FloatingActionButton.extended(
                heroTag: 'clear_route',
                onPressed: () => setState(() => _routePoints = []),
                backgroundColor: Colors.red,
                icon: const Icon(Icons.close, color: Colors.white),
                label: const Text(
                  'Xóa đường',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            if (_routePoints.isNotEmpty) const SizedBox(height: 10),
            SizedBox(
              width: 42,
              height: 42,
              child: FloatingActionButton(
                mini: true,
                heroTag: 'zoom_in',
                onPressed: _zoomIn,
                backgroundColor: Colors.white,
                child: const Icon(
                  Icons.add,
                  color: Color(0xFF2E7D32),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 42,
              height: 42,
              child: FloatingActionButton(
                mini: true,
                heroTag: 'zoom_out',
                onPressed: _zoomOut,
                backgroundColor: Colors.white,
                child: const Icon(
                  Icons.remove,
                  color: Color(0xFF2E7D32),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              heroTag: 'toggle_heatmap',
              onPressed: _toggleHeatmapMode,
              backgroundColor: _isHeatmapMode
                  ? Colors.deepOrange
                  : const Color(0xFF2E7D32),
              child: Icon(
                _isHeatmapMode
                    ? Icons.layers_clear
                    : Icons.local_fire_department,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
