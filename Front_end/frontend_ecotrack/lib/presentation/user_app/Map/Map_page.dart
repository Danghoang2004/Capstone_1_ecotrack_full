import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:frontend_ecotrack/core/services/hotspot_service.dart';
import 'package:frontend_ecotrack/data/models/Report.dart';
import 'package:frontend_ecotrack/data/models/hotspot_models.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:frontend_ecotrack/presentation/user_app/Map/goong_map_bridge.dart';

class MapPage extends StatefulWidget {
  final bool hideAppBar;

  const MapPage({super.key, this.hideAppBar = false});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _SimpleBounds {
  final LatLng southwest;
  final LatLng northeast;

  const _SimpleBounds({required this.southwest, required this.northeast});
}

class LatLng {
  final double latitude;
  final double longitude;
  const LatLng(this.latitude, this.longitude);
}

class MarkerId {
  final String value;
  const MarkerId(this.value);
}

class InfoWindow {
  final String? title;
  final String? snippet;
  const InfoWindow({this.title, this.snippet});
}

class BitmapDescriptor {
  static const double hueRed = 0;
  static const double hueOrange = 30;
  static const double hueGreen = 120;
  static const double hueAzure = 210;
  static const double hueBlue = 240;

  static double defaultMarkerWithHue(double hue) => hue;
}

class Marker {
  final MarkerId markerId;
  final LatLng position;
  final InfoWindow infoWindow;
  final double? icon;
  final VoidCallback? onTap;

  const Marker({
    required this.markerId,
    required this.position,
    this.infoWindow = const InfoWindow(),
    this.icon,
    this.onTap,
  });
}

class PolylineId {
  final String value;
  const PolylineId(this.value);
}

class Polyline {
  final PolylineId polylineId;
  final List<LatLng> points;
  final Color color;
  final int width;

  const Polyline({
    required this.polylineId,
    required this.points,
    required this.color,
    required this.width,
  });
}

class CircleId {
  final String value;
  const CircleId(this.value);
}

class Circle {
  final CircleId circleId;
  final LatLng center;
  final double radius;
  final Color fillColor;
  final int strokeWidth;

  const Circle({
    required this.circleId,
    required this.center,
    required this.radius,
    required this.fillColor,
    required this.strokeWidth,
  });
}

class _MapPageState extends State<MapPage> {
  LatLng _center = LatLng(16.0471, 108.2068);
  double _currentZoom = 14.0;
  WebViewController? _mobileWebViewController;
  bool _mobileWebViewLoaded = false;
  String _pinDataUri = '';

  bool _mapReady = false;
  bool _mapInitializing = false;
  bool _mapInitialized = false;
  String _mapStatus = 'Đang khởi tạo Goong map...';
  late final String _viewType;
  Object? _mapContainer;
  final GoongMapBridge _goongBridge = GoongMapBridge.instance;
  Timer? _mapInitRetryTimer;
  Timer? _mapReadyPoller;

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
    _viewType = 'goong-user-map-${DateTime.now().microsecondsSinceEpoch}';
    if (kIsWeb) {
      _registerViewFactory();
    } else {
      unawaited(_setupMobileGoongView());
    }
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
    _mapInitRetryTimer?.cancel();
    _mapReadyPoller?.cancel();
    if (kIsWeb) {
      try {
        _goongBridge.disposeMap();
      } catch (_) {
        // ignore
      }
    }
    super.dispose();
  }

  void _registerViewFactory() {
    _goongBridge.registerViewFactory(_viewType);
  }

  void _onPlatformViewCreated(int viewId) {
    _mapContainer ??= _goongBridge.findContainer(_viewType);
    _waitForContainerAndInit();
  }

  Future<void> _setupMobileGoongView() async {
    _pinDataUri = await _loadPinDataUri();

    _mobileWebViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'GoongMapChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _onMobileMapMessage(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _mobileWebViewLoaded = true;
            _initializeGoongMap();
          },
        ),
      )
      ..loadHtmlString(_buildMobileGoongHostHtml());

    if (mounted) setState(() {});
  }

  Future<String> _loadPinDataUri() async {
    try {
      final data = await rootBundle.load('assets/icons/pin.png');
      final bytes = data.buffer.asUint8List();
      return 'data:image/png;base64,${base64Encode(bytes)}';
    } catch (_) {
      return '';
    }
  }

  void _onMobileMapMessage(String raw) {
    if (!mounted) return;
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      if (decoded['type'] != 'camera') return;

      final double? lat = (decoded['lat'] as num?)?.toDouble();
      final double? lng = (decoded['lng'] as num?)?.toDouble();
      final double? zoom = (decoded['zoom'] as num?)?.toDouble();
      if (lat == null || lng == null || zoom == null) return;

      _center = LatLng(lat, lng);
      _currentZoom = zoom;

      if (!_isHeatmapMode) return;
      _hotspotDebounce?.cancel();
      _hotspotDebounce = Timer(const Duration(milliseconds: 600), () {
        _fetchHotspotsFromViewport();
      });
    } catch (_) {
      // ignore
    }
  }

  void _waitForContainerAndInit() {
    int attempts = 0;

    void check() {
      if (!mounted || _mapInitialized || _mapInitializing) {
        return;
      }

      final container = _mapContainer;
      final ready = _goongBridge.isContainerReady(container);

      if (ready) {
        _initializeGoongMap();
        return;
      }

      attempts += 1;
      if (attempts == 30) {
        _mapStatus = 'Đang chờ container Goong map sẵn sàng...';
        if (mounted) setState(() {});
      }

      Future.delayed(const Duration(milliseconds: 100), check);
    }

    check();
  }

  Future<void> _initializeGoongMap() async {
    if (_mapInitializing || _mapInitialized) {
      return;
    }

    _mapInitializing = true;

    try {
      final String mapKey = dotenv.env['GOONG_MAP_KEY'] ?? '';
      if (mapKey.isEmpty) {
        _mapStatus = 'Thiếu GOONG_MAP_KEY trong .env';
        if (mounted) setState(() {});
        return;
      }

      final styleUrl =
          'https://tiles.goong.io/assets/goong_map_web.json?api_key=$mapKey';

      _mapReadyPoller?.cancel();
      _mapReady = false;
      _mapStatus = 'Đang tải Goong map...';

      if (kIsWeb) {
        if (!_goongBridge.hasInitFunction) {
          _scheduleMapInitRetry();
          return;
        }

        final container = _mapContainer;
        if (!_goongBridge.isContainerReady(container)) {
          _scheduleMapInitRetry();
          return;
        }

        _goongBridge.initMap(
          container: container!,
          styleUrl: styleUrl,
          lng: _center.longitude,
          lat: _center.latitude,
          zoom: _currentZoom,
        );
      } else {
        if (!_mobileWebViewLoaded || _mobileWebViewController == null) {
          _scheduleMapInitRetry();
          return;
        }
        await _runMobileMapJs(
          'window.goongAdminMapInit(${jsonEncode(styleUrl)}, ${_center.longitude}, ${_center.latitude}, $_currentZoom);',
        );
      }

      _mapReadyPoller = Timer.periodic(const Duration(milliseconds: 150), (
        timer,
      ) async {
        if (!mounted) {
          timer.cancel();
          return;
        }

        try {
          final isReady = kIsWeb
              ? _goongBridge.isMapReady()
              : await _isMobileMapReady();
          if (isReady == true) {
            timer.cancel();
            _mapReady = true;
            _mapInitialized = true;
            _mapStatus = 'Goong map đã sẵn sàng';
            _syncGoongMapState();
            if (mounted) setState(() {});
          }
        } catch (_) {
          timer.cancel();
        }
      });
    } finally {
      _mapInitializing = false;
    }
  }

  Future<void> _runMobileMapJs(String script) async {
    final controller = _mobileWebViewController;
    if (controller == null) return;
    await controller.runJavaScript(script);
  }

  Future<bool> _isMobileMapReady() async {
    final controller = _mobileWebViewController;
    if (controller == null) return false;
    try {
      final dynamic result = await controller.runJavaScriptReturningResult(
        'window.goongAdminMapIsReady && window.goongAdminMapIsReady() === true',
      );
      return result.toString().contains('true');
    } catch (_) {
      return false;
    }
  }

  void _scheduleMapInitRetry() {
    if (!mounted || _mapReady || _mapInitialized) {
      return;
    }

    _mapInitRetryTimer?.cancel();
    _mapInitRetryTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted && !_mapReady && !_mapInitialized && !_mapInitializing) {
        _initializeGoongMap();
      }
    });
  }

  List<Map<String, dynamic>> _buildGoongReportPayload() {
    return _groupedReports.entries.map((entry) {
      final reportsAtPos = [...entry.value]
        ..sort((a, b) => (a.id).compareTo(b.id));
      final first = reportsAtPos.first;
      final parts = entry.key.split(',');
      final centerLat = parts.isNotEmpty
          ? double.tryParse(parts[0]) ?? first.latitude
          : first.latitude;
      final centerLng = parts.length > 1
          ? double.tryParse(parts[1]) ?? first.longitude
          : first.longitude;

      return <String, dynamic>{
        'reportId': first.id,
        'title': first.title,
        'description': first.description,
        'imageUrl': first.imageUrl,
        'latitude': centerLat,
        'longitude': centerLng,
        'status': _pickClusterStatus(reportsAtPos),
        'category': '',
        'count': reportsAtPos.length,
        'reports': reportsAtPos
            .map(
              (r) => <String, dynamic>{
                'id': r.id,
                'title': r.title,
                'description': r.description,
                'imageUrl': r.imageUrl,
                'latitude': r.latitude,
                'longitude': r.longitude,
                'status': r.status,
              },
            )
            .toList(),
      };
    }).toList();
  }

  String _pickClusterStatus(List<Report> reports) {
    final statuses = reports.map((r) => r.status.toUpperCase()).toSet();
    if (statuses.contains('PENDING')) return 'PENDING';
    if (statuses.contains('VERIFIED')) return 'VERIFIED';
    if (statuses.contains('CLEANED')) return 'CLEANED';
    if (reports.isEmpty) return 'UNKNOWN';
    return reports.first.status;
  }

  List<Map<String, dynamic>> _buildGoongHeatPayload(
    List<PredictedHeatmapPoint> points, {
    required bool predicted,
  }) {
    return points
        .map(
          (point) => <String, dynamic>{
            'lat': point.lat,
            'lng': point.lng,
            'intensity': point.intensity,
            'predictedCount7d': point.predictedCount7d,
            'predicted': predicted,
          },
        )
        .toList();
  }

  void _syncGoongMapState() {
    if (!_mapReady) {
      return;
    }

    try {
      final mode = _isHeatmapMode
          ? (_showPredictedHotspots ? 'heat_predicted' : 'heat_observed')
          : 'reports';

      if (kIsWeb) {
        _goongBridge.setMode(mode);
      } else {
        unawaited(
          _runMobileMapJs('window.goongAdminMapSetMode(${jsonEncode(mode)});'),
        );
      }

      if (mode == 'reports') {
        final reportsJson = jsonEncode(_buildGoongReportPayload());
        if (kIsWeb) {
          _goongBridge.setReports(reportsJson);
        } else {
          unawaited(
            _runMobileMapJs(
              'window.goongAdminMapSetReports(${jsonEncode(reportsJson)});',
            ),
          );
        }
      } else {
        final payload = _showPredictedHotspots
            ? _buildGoongHeatPayload(_predictedHeatmapPoints, predicted: true)
            : _buildGoongHeatPayload(_observedHeatmapPoints, predicted: false);
        final heatJson = jsonEncode(payload);
        if (kIsWeb) {
          _goongBridge.setHeatPoints(heatJson);
        } else {
          unawaited(
            _runMobileMapJs(
              'window.goongAdminMapSetHeatPoints(${jsonEncode(heatJson)});',
            ),
          );
        }
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _fetchHotspotsFromViewport() async {
    if (_isLoadingHotspots || !_isHeatmapMode) return;

    if (kIsWeb) {
      _isLoadingHotspots = true;
      try {
        final clusterFuture = _hotspotService.fetchClusterInArea(
          minLat: 8.0,
          maxLat: 24.0,
          minLng: 102.0,
          maxLng: 110.0,
        );

        final predictFuture = _hotspotService.fetchPredictionInArea(
          minLat: 8.0,
          maxLat: 24.0,
          minLng: 102.0,
          maxLng: 110.0,
        );

        final clusterResult = await clusterFuture;
        final predictResult = await predictFuture;

        if (!mounted) return;
        setState(() {
          _observedHeatmapPoints = _toObservedHeatmapPoints(
            clusterResult.hotspots,
          );
          _predictedHeatmapPoints = predictResult.heatmapPoints;
        });
        _syncGoongMapState();
      } catch (_) {
        // ignore
      } finally {
        _isLoadingHotspots = false;
      }
      return;
    }

    _isLoadingHotspots = true;
    try {
      final double span = max(0.08, 14 / pow(2, _currentZoom - 5));
      final double minLat = _center.latitude - span;
      final double maxLat = _center.latitude + span;
      final double minLng = _center.longitude - span;
      final double maxLng = _center.longitude + span;

      final clusterFuture = _hotspotService.fetchClusterInArea(
        minLat: minLat,
        maxLat: maxLat,
        minLng: minLng,
        maxLng: maxLng,
      );

      final predictFuture = _hotspotService.fetchPredictionInArea(
        minLat: minLat,
        maxLat: maxLat,
        minLng: minLng,
        maxLng: maxLng,
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
          _observedHeatmapPoints = _buildFallbackHeatmapFromReports(
            _SimpleBounds(
              southwest: LatLng(minLat, minLng),
              northeast: LatLng(maxLat, maxLng),
            ),
          );
        }

        _updateHeatmapCircles();
      });
      _syncGoongMapState();
    } catch (e) {
      debugPrint('Lỗi fetch hotspot: $e');
    } finally {
      _isLoadingHotspots = false;
    }
  }

  List<PredictedHeatmapPoint> _buildFallbackHeatmapFromReports(
    _SimpleBounds bounds,
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
    if (kIsWeb && _mapReady) {
      _goongBridge.zoomIn();
      return;
    }
    await _runMobileMapJs('window.goongAdminMapZoomIn();');
  }

  Future<void> _zoomOut() async {
    if (kIsWeb && _mapReady) {
      _goongBridge.zoomOut();
      return;
    }
    await _runMobileMapJs('window.goongAdminMapZoomOut();');
  }

  Future<void> _centerOnMe() async {
    if (_myLocation != null) {
      _center = _myLocation!;
      _currentZoom = max(_currentZoom, 16.0);
      await _runMobileMapJs(
        'window.goongAdminMapFlyTo(${_myLocation!.longitude}, ${_myLocation!.latitude}, $_currentZoom);',
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
    if (firstPos != null && _myLocation == null) {
      final LatLng initialPos = LatLng(firstPos.latitude, firstPos.longitude);
      setState(() {
        _myLocation = initialPos;
        _updateMarkers();
      });
      _center = initialPos;
      _currentZoom = 15;
      if (!kIsWeb) {
        await _runMobileMapJs(
          'window.goongAdminMapFlyTo(${initialPos.longitude}, ${initialPos.latitude}, $_currentZoom);',
        );
      }
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

  void _groupReportsByDistance(List<Report> reports) {
    const double clusterRadius = 40; // mét
    final List<Report> sortedReports = [...reports]
      ..sort((a, b) {
        final latCmp = a.latitude.compareTo(b.latitude);
        if (latCmp != 0) return latCmp;
        final lngCmp = a.longitude.compareTo(b.longitude);
        if (lngCmp != 0) return lngCmp;
        return a.id.compareTo(b.id);
      });

    final List<List<Report>> clusterReports = [];
    final List<LatLng> clusterCenters = [];

    for (final report in sortedReports) {
      int targetIndex = -1;
      double bestDistance = double.infinity;

      for (int i = 0; i < clusterCenters.length; i++) {
        final center = clusterCenters[i];
        final distance = _calculateDistance(
          report.latitude,
          report.longitude,
          center.latitude,
          center.longitude,
        );

        if (distance <= clusterRadius && distance < bestDistance) {
          bestDistance = distance;
          targetIndex = i;
        }
      }

      if (targetIndex == -1) {
        clusterReports.add([report]);
        clusterCenters.add(LatLng(report.latitude, report.longitude));
      } else {
        final cluster = clusterReports[targetIndex];
        cluster.add(report);
      }
    }

    final Map<String, List<Report>> grouped = {};
    for (int i = 0; i < clusterReports.length; i++) {
      final center = clusterCenters[i];
      final key =
          '${center.latitude.toStringAsFixed(7)},${center.longitude.toStringAsFixed(7)}';
      grouped[key] = clusterReports[i];
    }

    _groupedReports = grouped;
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
        _syncGoongMapState();
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
            'Nguồn bản đồ: Goong Maps',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  void _setReportView() {
    setState(() {
      _isHeatmapMode = false;
      _showPredictedHotspots = false;
      _circles.clear();
      _observedHeatmapPoints.clear();
      _predictedHeatmapPoints.clear();
    });
    _syncGoongMapState();
  }

  String _buildMobileGoongHostHtml() {
    final encodedPinDataUri = jsonEncode(_pinDataUri);
    return '''<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
  <link href="https://unpkg.com/maplibre-gl@4.7.1/dist/maplibre-gl.css" rel="stylesheet" />
  <script src="https://unpkg.com/maplibre-gl@4.7.1/dist/maplibre-gl.js"></script>
  <style>
    html, body, #map { width: 100%; height: 100%; margin: 0; padding: 0; overflow: hidden; }
  </style>
</head>
<body>
  <div id="map"></div>
  <script>
    (function () {
      const PIN_DATA_URI = $encodedPinDataUri;
      const state = {
        map: null,
        ready: false,
        mode: 'reports',
        reports: [],
        heatPoints: [],
        markers: [],
        popup: null,
        reportEventsBound: false,
      };

      function postCamera() {
        if (!window.GoongMapChannel || !state.map) return;
        const c = state.map.getCenter();
        window.GoongMapChannel.postMessage(JSON.stringify({
          type: 'camera',
          lat: c.lat,
          lng: c.lng,
          zoom: state.map.getZoom()
        }));
      }

      function clearLayers() {
        if (!state.map) return;

        if (state.popup) {
          state.popup.remove();
          state.popup = null;
        }

        for (const marker of state.markers) {
          marker.remove();
        }
        state.markers = [];

        const layers = ['goong-heat-outer', 'goong-heat-mid', 'goong-heat-core'];
        for (const id of layers) {
          if (state.map.getLayer(id)) state.map.removeLayer(id);
        }
        if (state.map.getLayer('goong-reports-circle')) state.map.removeLayer('goong-reports-circle');
        if (state.map.getSource('goong-heat')) state.map.removeSource('goong-heat');
        if (state.map.getSource('goong-reports')) state.map.removeSource('goong-reports');
      }

      function statusColor(status) {
        switch (String(status || '').toUpperCase()) {
          case 'PENDING':
            return '#f44336';
          case 'VERIFIED':
            return '#fb8c00';
          case 'CLEANED':
            return '#2e7d32';
          default:
            return '#3874c7';
        }
      }

      function escapeHtml(value) {
        return String(value || '')
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;')
          .replaceAll('"', '&quot;')
          .replaceAll("'", '&#39;');
      }

      function buildReportsPopupHtml(item) {
        const reports = Array.isArray(item.reports) && item.reports.length
          ? item.reports
          : [item];

        let html = '';
        html += '<div style="min-width:260px;max-width:320px;font-family:Arial,sans-serif;line-height:1.4;">';
        html += '<div style="font-weight:700;font-size:14px;margin-bottom:8px;color:#111827;">';
        html += 'Cụm báo cáo (' + reports.length + ')';
        html += '</div>';

        for (let i = 0; i < reports.length; i++) {
          const r = reports[i] || {};
          const title = escapeHtml(r.title || 'Không có tiêu đề');
          const desc = escapeHtml(r.description || 'Không có mô tả');
          const status = String(r.status || 'UNKNOWN').toUpperCase();
          const statusColorValue = statusColor(status);
          const imageUrl = String(r.imageUrl || '').trim();

          html += '<div style="padding:8px 0;border-top:' + (i === 0 ? 'none' : '1px solid #e5e7eb') + ';">';
          html += '<div style="font-weight:600;font-size:13px;color:#111827;">' + title + '</div>';
          html += '<div style="display:inline-block;margin-top:4px;padding:2px 8px;border-radius:999px;font-size:11px;font-weight:700;color:#fff;background:' + statusColorValue + ';">' + escapeHtml(status) + '</div>';
          html += '<div style="margin-top:6px;font-size:12px;color:#374151;">' + desc + '</div>';

          if (imageUrl) {
            html += '<div style="margin-top:6px;">';
            html += '<a href="' + escapeHtml(imageUrl) + '" target="_blank" rel="noopener noreferrer" style="font-size:12px;color:#2563eb;text-decoration:underline;">Xem ảnh đính kèm</a>';
            html += '</div>';
          }

          html += '</div>';
        }

        html += '</div>';
        return html;
      }

      function renderReports() {
        clearLayers();
        if (!state.reports.length) return;

        const features = state.reports.map((item) => ({
          type: 'Feature',
          geometry: {
            type: 'Point',
            coordinates: [Number(item.longitude), Number(item.latitude)],
          },
          properties: {
            statusKey: String(item.status || 'UNKNOWN').toUpperCase(),
            count: Number(item.count || 1),
            popupHtml: buildReportsPopupHtml(item),
          },
        }));

        state.map.addSource('goong-reports', {
          type: 'geojson',
          data: {
            type: 'FeatureCollection',
            features,
          },
        });

        state.map.addLayer({
          id: 'goong-reports-circle',
          type: 'circle',
          source: 'goong-reports',
          paint: {
            'circle-color': [
              'match',
              ['get', 'statusKey'],
              'PENDING', '#f44336',
              'VERIFIED', '#fb8c00',
              'CLEANED', '#2e7d32',
              '#3874c7',
            ],
            'circle-radius': [
              'interpolate',
              ['linear'],
              ['coalesce', ['get', 'count'], 1],
              1, 8,
              3, 11,
              10, 14,
            ],
            'circle-opacity': 0.92,
            'circle-stroke-color': '#ffffff',
            'circle-stroke-width': 2,
          },
        });

        if (!state.reportEventsBound) {
          state.reportEventsBound = true;

          state.map.on('click', 'goong-reports-circle', (event) => {
            if (!event.features || event.features.length === 0) return;

            const feature = event.features[0];
            const popupHtml = feature.properties && feature.properties.popupHtml
              ? feature.properties.popupHtml
              : 'Không có dữ liệu';

            if (state.popup) {
              state.popup.remove();
              state.popup = null;
            }

            state.popup = new maplibregl.Popup({ offset: 18, closeButton: true, closeOnClick: true })
              .setLngLat(feature.geometry.coordinates)
              .setHTML(popupHtml)
              .addTo(state.map);
          });

          state.map.on('mouseenter', 'goong-reports-circle', () => {
            state.map.getCanvas().style.cursor = 'pointer';
          });

          state.map.on('mouseleave', 'goong-reports-circle', () => {
            state.map.getCanvas().style.cursor = '';
          });
        }
      }

      function renderHeat() {
        clearLayers();
        if (!state.heatPoints.length) return;

        const features = state.heatPoints.map((point) => ({
          type: 'Feature',
          geometry: { type: 'Point', coordinates: [Number(point.lng), Number(point.lat)] },
          properties: { intensity: Number(point.intensity || 0) }
        }));

        state.map.addSource('goong-heat', {
          type: 'geojson',
          data: { type: 'FeatureCollection', features }
        });

        const predicted = state.mode === 'heat_predicted';
        const colorOuter = predicted ? '#dc2626' : '#f59e0b';
        const colorMid = predicted ? '#fb7185' : '#fb923c';
        const colorCore = predicted ? '#991b1b' : '#d97706';

        state.map.addLayer({
          id: 'goong-heat-outer',
          type: 'circle',
          source: 'goong-heat',
          paint: {
            'circle-color': colorOuter,
            'circle-radius': ['interpolate', ['linear'], ['get', 'intensity'], 0, 12, 1, 36],
            'circle-opacity': 0.16,
            'circle-blur': 0.7
          }
        });

        state.map.addLayer({
          id: 'goong-heat-mid',
          type: 'circle',
          source: 'goong-heat',
          paint: {
            'circle-color': colorMid,
            'circle-radius': ['interpolate', ['linear'], ['get', 'intensity'], 0, 8, 1, 24],
            'circle-opacity': 0.28,
            'circle-blur': 0.45
          }
        });

        state.map.addLayer({
          id: 'goong-heat-core',
          type: 'circle',
          source: 'goong-heat',
          paint: {
            'circle-color': colorCore,
            'circle-radius': ['interpolate', ['linear'], ['get', 'intensity'], 0, 4, 1, 12],
            'circle-opacity': 0.55,
            'circle-blur': 0.1
          }
        });
      }

      function render() {
        if (!state.map || !state.map.isStyleLoaded()) return;
        if (state.mode === 'reports') renderReports();
        else renderHeat();
      }

      window.goongAdminMapInit = function (styleUrl, lng, lat, zoom) {
        if (state.map) {
          state.map.jumpTo({ center: [Number(lng), Number(lat)], zoom: Number(zoom) });
          return;
        }

        state.map = new maplibregl.Map({
          container: 'map',
          style: styleUrl,
          center: [Number(lng), Number(lat)],
          zoom: Number(zoom),
          attributionControl: false
        });

        state.map.on('load', function () {
          state.ready = true;
          render();
          postCamera();
        });

        state.map.on('moveend', postCamera);
        state.map.on('zoomend', postCamera);
      };

      window.goongAdminMapIsReady = function () {
        return state.ready === true;
      };

      window.goongAdminMapSetMode = function (mode) {
        state.mode = mode || 'reports';
        render();
      };

      window.goongAdminMapSetReports = function (json) {
        try {
          state.reports = JSON.parse(json || '[]');
        } catch (_) {
          state.reports = [];
        }
        render();
      };

      window.goongAdminMapSetHeatPoints = function (json) {
        try {
          state.heatPoints = JSON.parse(json || '[]');
        } catch (_) {
          state.heatPoints = [];
        }
        render();
      };

      window.goongAdminMapZoomIn = function () {
        if (state.map) state.map.zoomIn();
      };

      window.goongAdminMapZoomOut = function () {
        if (state.map) state.map.zoomOut();
      };

      window.goongAdminMapFlyTo = function (lng, lat, zoom) {
        if (!state.map) return;
        state.map.flyTo({ center: [Number(lng), Number(lat)], zoom: Number(zoom || state.map.getZoom()) });
      };
    })();
  </script>
</body>
</html>''';
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
          if (kIsWeb)
            Positioned.fill(
              child: HtmlElementView(
                viewType: _viewType,
                onPlatformViewCreated: _onPlatformViewCreated,
              ),
            )
          else
            Positioned.fill(
              child: _mobileWebViewController == null
                  ? const Center(child: CircularProgressIndicator())
                  : WebViewWidget(controller: _mobileWebViewController!),
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
          if (kIsWeb && !_mapReady)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _mapStatus,
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
            ),
          if (!kIsWeb && (dotenv.env['GOONG_MAP_KEY'] ?? '').isEmpty)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Text(
                  'Thiếu GOONG_MAP_KEY trong .env',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
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
                  onPressed: _setReportView,
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
