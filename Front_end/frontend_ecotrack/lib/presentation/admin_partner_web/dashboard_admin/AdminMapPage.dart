import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:frontend_ecotrack/core/services/hotspot_service.dart';
import 'package:frontend_ecotrack/core/services/ReportService.dart';
import 'package:frontend_ecotrack/data/models/hotspot_models.dart';
import 'package:latlong2/latlong.dart';
import 'package:frontend_ecotrack/data/models/report_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class AdminMapPage extends StatefulWidget {
  const AdminMapPage({super.key});

  @override
  State<AdminMapPage> createState() => _AdminMapPageState();
}

class _AdminMapPageState extends State<AdminMapPage> {
  final MapController _mapController = MapController();
  final ReportServiceAdmin _reportService = ReportServiceAdmin();
  final HotspotService _hotspotService = HotspotService();

  List<Report> _reports = [];

  // ================== [THÊM MỚI] ==================
  final Distance _distance = const Distance();
  List<List<Report>> _groupedReports = [];
  Timer? _hotspotDebounce;
  bool _isLoadingHotspots = false;
  bool _isHeatmapMode = false;
  List<PredictedHeatmapPoint> _observedHeatmapPoints = [];
  List<PredictedHeatmapPoint> _predictedHeatmapPoints = [];
  // =================================================

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    try {
      final data = await _reportService.fetchAllReports();
      if (mounted) {
        setState(() {
          _reports = data;
        });

        // ===== [THÊM] Gom nhóm GPS trong bán kính 40m =====
        _groupReportsByDistance(data, radiusInMeters: 40);
      }
    } catch (e) {
      debugPrint("Lỗi tải báo cáo: $e");
    }
  }

  // ================== [THÊM MỚI] ==================
  void _groupReportsByDistance(
    List<Report> reports, {
    double radiusInMeters = 40,
  }) {
    final List<List<Report>> groups = [];

    for (final report in reports) {
      bool added = false;

      for (final group in groups) {
        final center = group.first;

        final double dist = _distance(
          LatLng(center.latitude, center.longitude),
          LatLng(report.latitude, report.longitude),
        );

        if (dist <= radiusInMeters) {
          group.add(report);
          added = true;
          break;
        }
      }

      if (!added) {
        groups.add([report]);
      }
    }

    setState(() {
      _groupedReports = groups;
    });
  }
  // =================================================

  @override
  void dispose() {
    _hotspotDebounce?.cancel();
    super.dispose();
  }

  void _onMapPositionChanged(MapPosition position, bool hasGesture) {
    if (!_isHeatmapMode) return;

    _hotspotDebounce?.cancel();
    _hotspotDebounce = Timer(const Duration(milliseconds: 600), () {
      _fetchHotspots(position.bounds);
    });
  }

  Future<void> _fetchHotspots([LatLngBounds? bounds]) async {
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
      if (t >= 0.85) return Colors.red;
      if (t >= 0.6) return Colors.deepOrange;
      if (t >= 0.35) return Colors.orangeAccent;
      return Colors.amber;
    }

    if (t >= 0.85) return Colors.deepOrange;
    if (t >= 0.6) return Colors.orange;
    if (t >= 0.35) return Colors.amber;
    return Colors.yellow;
  }

  List<CircleMarker> _buildHeatCircles(
    List<PredictedHeatmapPoint> points, {
    required bool predicted,
  }) {
    final List<CircleMarker> circles = [];
    for (final point in points) {
      final double t = point.intensity.clamp(0.0, 1.0);
      final Color base = _heatColor(t, predicted: predicted);

      // Layer 1: Large outer heatmap layer - visible from far away
      circles.add(
        CircleMarker(
          point: LatLng(point.lat, point.lng),
          radius: 400 + (t * 400),
          useRadiusInMeter: true,
          color: base.withOpacity(
            predicted ? 0.15 + (t * 0.25) : 0.12 + (t * 0.23),
          ),
          borderStrokeWidth: 0,
        ),
      );
      // Layer 2: Medium layer - mid-range visibility
      circles.add(
        CircleMarker(
          point: LatLng(point.lat, point.lng),
          radius: 240 + (t * 260),
          useRadiusInMeter: true,
          color: base.withOpacity(
            predicted ? 0.25 + (t * 0.30) : 0.22 + (t * 0.28),
          ),
          borderStrokeWidth: 0,
        ),
      );
      // Layer 3: Core layer - most visible
      circles.add(
        CircleMarker(
          point: LatLng(point.lat, point.lng),
          radius: 120 + (t * 200),
          useRadiusInMeter: true,
          color: base.withOpacity(
            predicted ? 0.40 + (t * 0.35) : 0.38 + (t * 0.37),
          ),
          borderStrokeWidth: 0,
        ),
      );
    }
    return circles;
  }

  String _buildImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith("http")) return path;

    final String baseUrl =
        dotenv.env['API_BASE_URL'] ?? "http://192.168.1.89:8080";
    return "$baseUrl$path";
  }

  void _showReportDetail(BuildContext context, Report report) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.network(
                      _buildImageUrl(report.imageUrl),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, size: 50),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatusBadge(report.status),
                        Text(
                          DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format(report.createdAt),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      report.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text("Loại rác: ${report.category}"),
                    const SizedBox(height: 12),
                    Text(report.description),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================== [THÊM MỚI] ==================
  void _showGroupedAdminReports(BuildContext context, List<Report> reports) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              height: 5,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Có ${reports.length} báo cáo gần nhau",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: reports.length,
                itemBuilder: (_, index) {
                  final r = reports[index];
                  return ListTile(
                    leading: Icon(
                      Icons.location_pin,
                      color: _getStatusColor(r.status),
                    ),
                    title: Text(r.title),
                    subtitle: Text(
                      "${r.latitude}, ${r.longitude}",
                      maxLines: 1,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showReportDetail(context, r);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  // =================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: LatLng(16.0471, 108.2068),
              zoom: 12.0,
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

              // ======= [THAY MARKER THEO NHÓM] =======
              if (!_isHeatmapMode)
                MarkerLayer(
                  markers: _groupedReports.map((group) {
                    final first = group.first;

                    return Marker(
                      point: LatLng(first.latitude, first.longitude),
                      width: 50,
                      height: 50,
                      builder: (_) => GestureDetector(
                        onTap: () {
                          if (group.length == 1) {
                            _showReportDetail(context, first);
                          } else {
                            _showGroupedAdminReports(context, group);
                          }
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.location_pin,
                              size: 45,
                              color: _getStatusColor(first.status),
                            ),
                            if (group.length > 1)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: const BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    "${group.length}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
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
          Positioned(
            top: 50,
            right: 12,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ChoiceChip(
                        label: const Text('Báo cáo'),
                        selected: !_isHeatmapMode,
                        onSelected: (_) =>
                            setState(() => _isHeatmapMode = false),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Heatmap'),
                        selected: _isHeatmapMode,
                        onSelected: (_) {
                          final bool shouldFetch = !_isHeatmapMode;
                          setState(() => _isHeatmapMode = true);
                          if (shouldFetch) {
                            _fetchHotspots();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _buildMapLegend(),
              ],
            ),
          ),
          if (_isLoadingHotspots && _isHeatmapMode)
            const Positioned(
              top: 20,
              left: 12,
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return const Color.fromARGB(255, 196, 30, 30);
      case 'VERIFIED':
        return const Color.fromARGB(255, 224, 149, 10);
      case 'CLEANED':
        return Colors.green;
      case 'REJECTED':
        return const Color.fromARGB(255, 155, 154, 154);
      default:
        return Colors.grey;
    }
  }

  Widget _buildMapLegend() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Chú thích",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          if (_isHeatmapMode) ...[
            _legendItem("Nhiệt thấp", Colors.yellow),
            _legendItem("Nhiệt trung bình", Colors.orange),
            _legendItem("Nhiệt cao / nguy cơ cao", Colors.red),
          ] else ...[
            _legendItem("Chờ duyệt", _getStatusColor("PENDING")),
            _legendItem("Đã xác Thực", _getStatusColor("VERIFIED")),
            _legendItem("Đã dọn dẹp", _getStatusColor("CLEANED")),
            _legendItem("Bị Từ Chối", _getStatusColor("REJECTED")),
          ],
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
