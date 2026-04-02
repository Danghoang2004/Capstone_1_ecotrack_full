import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:frontend_ecotrack/core/services/hotspot_service.dart';
import 'package:frontend_ecotrack/data/models/Report.dart';
import 'package:frontend_ecotrack/data/models/hotspot_models.dart';
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
  GoogleMapController? _mapController;
  LatLng _center = LatLng(16.0471, 108.2068);
  double _currentZoom = 14.0;

  final ApiClient apiClient = ApiClient(storage: const FlutterSecureStorage());
  final HotspotService _hotspotService = HotspotService();

  List<Report> _reports = [];
  Map<String, List<Report>> _groupedReports = {};

  Timer? _timer;
  Timer? _hotspotDebounce;
  List<LatLng> _routePoints = [];
  bool _isRouting = false;
  bool _isLoadingHotspots = false;
  bool _isHeatmapMode = false;
  bool _showPredictedHotspots = false;
  LatLng? _myLocation;
  List<PredictedHeatmapPoint> _observedHeatmapPoints = [];
  List<PredictedHeatmapPoint> _predictedHeatmapPoints = [];
  StreamSubscription<Position>? _positionStreamSubscription;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Set<Circle> _circles = {};

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

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onCameraChange(CameraPosition position) {
    _center = position.target;
    _currentZoom = position.zoom;

    if (!_isHeatmapMode) return;

    _hotspotDebounce?.cancel();
    _hotspotDebounce = Timer(const Duration(milliseconds: 600), () {
      _fetchHotspotsFromViewport();
    });
  }

  Future<void> _fetchHotspotsFromViewport() async {
    if (_mapController == null || _isLoadingHotspots || !_isHeatmapMode) return;

    _isLoadingHotspots = true;
    try {
      final bounds = await _mapController!.getVisibleRegion();

      final clusterFuture = _hotspotService.fetchClusterInArea(
        minLat: bounds.southwest.latitude,
        maxLat: bounds.northeast.latitude,
        minLng: bounds.southwest.longitude,
        maxLng: bounds.northeast.longitude,
      );

      final predictFuture = _hotspotService.fetchPredictionInArea(
        minLat: bounds.southwest.latitude,
        maxLat: bounds.northeast.latitude,
        minLng: bounds.southwest.longitude,
        maxLng: bounds.northeast.longitude,
      );

      final clusterResult = await clusterFuture;
      final predictResult = await predictFuture;

      if (!mounted) return;

      debugPrint('Cluster hotspots: ${clusterResult.hotspots.length}');
      debugPrint(
        'Predicted heatmap points: ${predictResult.heatmapPoints.length}',
      );

      setState(() {
        _observedHeatmapPoints = _toObservedHeatmapPoints(
          clusterResult.hotspots,
        );
        _predictedHeatmapPoints = predictResult.heatmapPoints;

        if (_observedHeatmapPoints.isEmpty && _predictedHeatmapPoints.isEmpty) {
          _observedHeatmapPoints = _buildFallbackHeatmapFromReports(bounds);
        }

        _updateHeatmapCircles();
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
      return r.latitude >= bounds.southwest.latitude &&
          r.latitude <= bounds.northeast.latitude &&
          r.longitude >= bounds.southwest.longitude &&
          r.longitude <= bounds.northeast.longitude;
    }).toList();

    if (reportsInView.isEmpty) return [];

    const double cellSize = 0.0035;
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

  void _updateHeatmapCircles() {
    _circles.clear();

    if (_showPredictedHotspots) {
      _circles.addAll(
        _buildHeatCircles(_predictedHeatmapPoints, predicted: true),
      );
      return;
    }

    _circles.addAll(
      _buildHeatCircles(_observedHeatmapPoints, predicted: false),
    );
  }

  List<Circle> _buildHeatCircles(
    List<PredictedHeatmapPoint> points, {
    required bool predicted,
  }) {
    final List<Circle> circles = [];
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
          Circle(
            circleId: CircleId('${predicted}_${point.lat}_${point.lng}_$i'),
            center: LatLng(point.lat, point.lng),
            radius: baseRadius * radiusScale[i],
            fillColor: layerColor.withOpacity(
              (opacityScale[i] * (0.8 + smoothT * 0.8)).clamp(0.0, 0.45),
            ),
            strokeWidth: 0,
          ),
        );
      }

      circles.add(
        Circle(
          circleId: CircleId('${predicted}_${point.lat}_${point.lng}_core'),
          center: LatLng(point.lat, point.lng),
          radius: baseRadius * 0.55,
          fillColor: _heatColor(
            (smoothT + 0.08).clamp(0.0, 1.0),
            predicted: predicted,
          ).withOpacity((0.22 + smoothT * 0.30).clamp(0.0, 0.55)),
          strokeWidth: 0,
        ),
      );
    }
    return circles;
  }

  void _toggleHeatmapMode() {
    final bool toHeatmap = !_isHeatmapMode;
    setState(() {
      _isHeatmapMode = toHeatmap;
      _showPredictedHotspots = false;
      if (toHeatmap) {
        _markers.clear();
        _updateHeatmapCircles();
      } else {
        _circles.clear();
      }
    });
    if (toHeatmap) {
      _fetchHotspotsFromViewport();
    }
  }

  void _setHeatmapView({required bool predicted}) {
    setState(() {
      _isHeatmapMode = true;
      _showPredictedHotspots = predicted;
      _markers.clear();
      _updateHeatmapCircles();
    });

    _fetchHotspotsFromViewport();
  }

  Future<void> _zoomIn() async {
    if (_mapController != null) {
      await _mapController!.animateCamera(CameraUpdate.zoomIn());
    }
  }

  Future<void> _zoomOut() async {
    if (_mapController != null) {
      await _mapController!.animateCamera(CameraUpdate.zoomOut());
    }
  }

  Future<void> _centerOnMe() async {
    if (_myLocation != null && _mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_myLocation!, 16.0),
      );
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
                _updateMarkers();
              });
            }
          },
        );

    Position? firstPos = await Geolocator.getLastKnownPosition();
    if (firstPos != null && _myLocation == null && _mapController != null) {
      final LatLng initialPos = LatLng(firstPos.latitude, firstPos.longitude);
      setState(() {
        _myLocation = initialPos;
        _updateMarkers();
      });
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(initialPos, 15),
      );
    }
  }

  void _updateMarkers() {
    _markers.clear();

    if (_myLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('my_location'),
          position: _myLocation!,
          infoWindow: const InfoWindow(title: 'Vị trí của tôi'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // In heatmap modes, do not render report markers to avoid overlay.
    if (_isHeatmapMode) return;

    for (final entry in _groupedReports.entries) {
      final reportsAtPos = entry.value;
      final firstReport = reportsAtPos.first;

      _markers.add(
        Marker(
          markerId: MarkerId('report_${firstReport.id}'),
          position: LatLng(firstReport.latitude, firstReport.longitude),
          infoWindow: InfoWindow(
            title: firstReport.title,
            snippet: '${reportsAtPos.length} báo cáo',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _statusToHue(firstReport.status),
          ),
          onTap: () => _showGroupedReportDetails(reportsAtPos),
        ),
      );
    }
  }

  double _statusToHue(String status) {
    switch (status) {
      case 'PENDING':
        return BitmapDescriptor.hueRed;
      case 'VERIFIED':
        return BitmapDescriptor.hueOrange;
      case 'CLEANED':
        return BitmapDescriptor.hueGreen;
      default:
        return BitmapDescriptor.hueAzure;
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
    Map<String, List<Report>> clusters = {};

    for (final report in reports) {
      bool addedToCluster = false;

      for (final entry in clusters.entries) {
        final firstReport = entry.value.first;
        final double dist = _calculateDistance(
          report.latitude,
          report.longitude,
          firstReport.latitude,
          firstReport.longitude,
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

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusM = 6371000;
    final double dLat = _toRad(lat2 - lat1);
    final double dLon = _toRad(lon2 - lon1);
    final double a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2));
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusM * c;
  }

  double _toRad(double degree) {
    return degree * 3.14159265359 / 180;
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
        boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 4)],
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
            if (_showPredictedHotspots) ...[
              _buildLegendItem(Colors.yellow, "Dự đoán thấp"),
              _buildLegendItem(Colors.orange, "Dự đoán trung bình"),
              _buildLegendItem(Colors.red, "Dự đoán cao"),
            ] else ...[
              _buildLegendItem(Colors.yellow, "Nhiệt thấp"),
              _buildLegendItem(Colors.orange, "Nhiệt trung bình"),
              _buildLegendItem(Colors.red, "Nhiệt cao / nguy cơ cao"),
            ],
          ] else ...[
            _buildLegendItem(Colors.red, "Chờ duyệt"),
            _buildLegendItem(Colors.orange, "Đã xác thực"),
            _buildLegendItem(Colors.green, "Đã dọn dẹp"),
            _buildLegendItem(
              const Color.fromARGB(255, 56, 116, 199),
              "không được duyệt",
            ),
          ],
          if (_isHeatmapMode) ...[
            const SizedBox(height: 6),
            Text(
              _showPredictedHotspots
                  ? 'Đang xem dự đoán 7 ngày tới'
                  : 'Đang xem điểm nóng từ lịch sử báo cáo',
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
          const SizedBox(height: 6),
          const Text(
            'Nguồn bản đồ: Google Maps',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _updateMarkers();

    if (_isRouting) {
      _polylines.clear();
    } else if (_routePoints.isNotEmpty && _polylines.isEmpty) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: _routePoints,
          color: Colors.blueAccent,
          width: 5,
        ),
      );
    }

    return Scaffold(
      appBar: widget.hideAppBar
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF2E7D32),
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
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: _currentZoom,
            ),
            onCameraMove: _onCameraChange,
            markers: _markers,
            polylines: _polylines,
            circles: _circles,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
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
          Positioned(
            bottom: 50,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'zoom_in',
                  mini: true,
                  onPressed: _zoomIn,
                  backgroundColor: const Color(0xFF2E7D32),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoom_out',
                  mini: true,
                  onPressed: _zoomOut,
                  backgroundColor: const Color(0xFF2E7D32),
                  child: const Icon(Icons.remove, color: Colors.white),
                ),
                const SizedBox(height: 8),
                // Mode buttons - Reports
                FloatingActionButton(
                  heroTag: 'mode_reports',
                  mini: true,
                  onPressed: () {
                    setState(() {
                      _isHeatmapMode = false;
                      _showPredictedHotspots = false;
                      _circles.clear();
                      _observedHeatmapPoints.clear();
                      _predictedHeatmapPoints.clear();
                    });
                  },
                  backgroundColor: !_isHeatmapMode ? Colors.blue : Colors.grey,
                  child: const Icon(Icons.list, color: Colors.white),
                ),
                const SizedBox(height: 8),
                // Mode buttons - Hotspots
                FloatingActionButton(
                  heroTag: 'mode_hotspots',
                  mini: true,
                  onPressed: () => _setHeatmapView(predicted: false),
                  backgroundColor: _isHeatmapMode && !_showPredictedHotspots
                      ? Colors.orange
                      : Colors.grey,
                  child: const Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                // Mode buttons - Prediction
                FloatingActionButton(
                  heroTag: 'mode_prediction',
                  mini: true,
                  onPressed: () => _setHeatmapView(predicted: true),
                  backgroundColor: _isHeatmapMode && _showPredictedHotspots
                      ? Colors.deepOrange
                      : Colors.grey,
                  child: const Icon(Icons.show_chart, color: Colors.white),
                ),
                if (_routePoints.isNotEmpty) const SizedBox(height: 10),
                if (_routePoints.isNotEmpty)
                  FloatingActionButton.extended(
                    heroTag: 'clear_route',
                    onPressed: () {
                      setState(() {
                        _routePoints = [];
                        _polylines.clear();
                      });
                    },
                    backgroundColor: Colors.red,
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: const Text(
                      'Xóa đường',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
