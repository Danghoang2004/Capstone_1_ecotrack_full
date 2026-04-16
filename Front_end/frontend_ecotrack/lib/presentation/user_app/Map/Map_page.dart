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
  static const Color _reportPendingColor = Color(0xFFF44336);
  static const Color _reportVerifiedColor = Color(0xFFFB8C00);
  static const Color _reportCleanedColor = Color(0xFF2E7D32);
  static const Color _reportRejectedColor = Color(0xFF9CA3AF);
  static const Color _heatObservedLowColor = Color(0xFF22C55E);
  static const Color _heatObservedMediumColor = Color(0xFFF59E0B);
  static const Color _heatObservedHighColor = Color(0xFFEF4444);

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
  LatLng? _myLocation;
  List<PredictedHeatmapPoint> _observedHeatmapPoints = [];
  LatLng? _lastHotspotFetchCenter;
  double? _lastHotspotFetchZoom;
  DateTime? _lastHotspotFetchAt;
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
      if (!_shouldRequestHotspots()) return;
      _hotspotDebounce?.cancel();
      _hotspotDebounce = Timer(const Duration(milliseconds: 900), () {
        _fetchHotspotsFromViewport();
      });
    } catch (_) {
      // ignore
    }
  }

  bool _shouldRequestHotspots() {
    final now = DateTime.now();
    final lastAt = _lastHotspotFetchAt;
    if (lastAt != null && now.difference(lastAt).inMilliseconds < 1200) {
      return false;
    }

    final lastCenter = _lastHotspotFetchCenter;
    final lastZoom = _lastHotspotFetchZoom;
    if (lastCenter == null || lastZoom == null) {
      return true;
    }

    final movedMeters = Geolocator.distanceBetween(
      lastCenter.latitude,
      lastCenter.longitude,
      _center.latitude,
      _center.longitude,
    );
    final zoomDelta = (_currentZoom - lastZoom).abs();
    return movedMeters >= 120 || zoomDelta >= 0.35;
  }

  void _markHotspotRequested() {
    _lastHotspotFetchCenter = _center;
    _lastHotspotFetchZoom = _currentZoom;
    _lastHotspotFetchAt = DateTime.now();
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
    const Set<String> _mapVisibleReportStatuses = {'VERIFIED', 'CLEANED'};
    const int _popupDetailLimit = 5;
    const int _popupDescriptionLimit = 60;

    return _groupedReports.entries
        .map((entry) {
          final reportsAtPos = [...entry.value]
            ..sort((a, b) => (a.id).compareTo(b.id));

          // Filter only visible statuses
          final visibleReports =
              reportsAtPos
                  .where(
                    (r) => _mapVisibleReportStatuses.contains(
                      r.status.toUpperCase(),
                    ),
                  )
                  .toList()
                ..sort((a, b) => (a.id).compareTo(b.id));

          if (visibleReports.isEmpty) return null;

          final first = visibleReports.first;
          final parts = entry.key.split(',');
          final centerLat = parts.isNotEmpty
              ? double.tryParse(parts[0]) ?? first.latitude
              : first.latitude;
          final centerLng = parts.length > 1
              ? double.tryParse(parts[1]) ?? first.longitude
              : first.longitude;

          final displayReports = visibleReports
              .take(_popupDetailLimit)
              .toList();

          return <String, dynamic>{
            'reportId': first.id,
            'title': first.title,
            'description': first.description,
            'imageUrl': first.imageUrl,
            'latitude': centerLat,
            'longitude': centerLng,
            'status': _pickClusterStatus(visibleReports),
            'category': '',
            'count': visibleReports.length,
            'overflowCount': visibleReports.length - displayReports.length,
            'reports': displayReports
                .map(
                  (r) => <String, dynamic>{
                    'id': r.id,
                    'title': r.title,
                    'description': r.description.length > _popupDescriptionLimit
                        ? '${r.description.substring(0, _popupDescriptionLimit)}...'
                        : r.description,
                    'imageUrl': r.imageUrl,
                    'latitude': r.latitude,
                    'longitude': r.longitude,
                    'status': r.status,
                  },
                )
                .toList(),
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  String _pickClusterStatus(List<Report> reports) {
    final statuses = reports.map((r) => r.status.toUpperCase()).toSet();
    // CLEANED has highest priority so a cleaned area immediately turns green.
    if (statuses.contains('CLEANED')) return 'CLEANED';
    if (statuses.contains('PENDING')) return 'PENDING';
    if (statuses.contains('VERIFIED')) return 'VERIFIED';
    if (reports.isEmpty) return 'UNKNOWN';
    return reports.first.status;
  }

  List<Map<String, dynamic>> _buildGoongHeatPayload(
    List<PredictedHeatmapPoint> points,
  ) {
    return points
        .map(
          (point) => <String, dynamic>{
            'lat': point.lat,
            'lng': point.lng,
            'intensity': point.intensity,
            'reportCount': point.reportCount,
            'count': point.reportCount,
          },
        )
        .toList();
  }

  void _syncGoongMapState() {
    if (!_mapReady) {
      return;
    }

    try {
      final mode = _isHeatmapMode ? 'heat_observed' : 'reports';

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
        final payload = _buildGoongHeatPayload(_observedHeatmapPoints);
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
    _markHotspotRequested();

    if (kIsWeb) {
      _isLoadingHotspots = true;
      try {
        final clusterResult = await _hotspotService.fetchClusterInArea(
          minLat: 8.0,
          maxLat: 24.0,
          minLng: 102.0,
          maxLng: 110.0,
        );

        if (!mounted) return;
        setState(() {
          _observedHeatmapPoints = _buildClusterDataPoints(
            clusterResult.hotspots,
            isPredicted: false,
          );
          if (_observedHeatmapPoints.isEmpty) {
            _observedHeatmapPoints = _buildFallbackHeatmapFromAllReports();
          }
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

      final clusterResult = await clusterFuture;

      if (!mounted) return;

      debugPrint('Cluster hotspots: ${clusterResult.hotspots.length}');

      setState(() {
        _observedHeatmapPoints = _buildClusterDataPoints(
          clusterResult.hotspots,
          isPredicted: false,
        );

        if (_observedHeatmapPoints.isEmpty) {
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
        reportCount: count,
      );
    }).toList();
  }

  List<PredictedHeatmapPoint> _buildClusterDataPoints(
    List<HotspotZone> zones, {
    required bool isPredicted,
  }) {
    if (zones.isEmpty) return [];

    final int maxCount = zones
        .map((z) {
          if (isPredicted) {
            return z.predictedCount7d ?? z.reportCount;
          } else {
            return z.reportCount;
          }
        })
        .fold<int>(1, (acc, value) => value > acc ? value : acc);

    return zones.map((zone) {
      final int count = isPredicted
          ? (zone.predictedCount7d ?? zone.reportCount)
          : zone.reportCount;

      return PredictedHeatmapPoint(
        lat: zone.centerLat,
        lng: zone.centerLng,
        intensity: (count / maxCount).clamp(0.0, 1.0),
        predictedCount7d: isPredicted ? count : 0,
        reportCount: !isPredicted ? count : 0,
      );
    }).toList();
  }

  List<PredictedHeatmapPoint> _buildFallbackHeatmapFromAllReports() {
    final reports = _reports.where((r) => r.status != 'REJECTED').toList();
    if (reports.isEmpty) return [];

    const double cellSize = 0.0035;
    final Map<String, int> counts = {};
    final Map<String, double> sumLat = {};
    final Map<String, double> sumLng = {};

    for (final r in reports) {
      final int latCell = (r.latitude / cellSize).floor();
      final int lngCell = (r.longitude / cellSize).floor();
      final key = '$latCell:$lngCell';

      counts[key] = (counts[key] ?? 0) + 1;
      sumLat[key] = (sumLat[key] ?? 0) + r.latitude;
      sumLng[key] = (sumLng[key] ?? 0) + r.longitude;
    }

    final int maxCount = counts.values.fold<int>(1, (a, b) => b > a ? b : a);
    return counts.entries.map((entry) {
      final key = entry.key;
      final count = entry.value;
      return PredictedHeatmapPoint(
        lat: (sumLat[key] ?? 0) / count,
        lng: (sumLng[key] ?? 0) / count,
        intensity: (count / maxCount).clamp(0.0, 1.0),
        predictedCount7d: 0,
        reportCount: count,
      );
    }).toList();
  }

  Color _heatColor(double intensity) {
    final double t = intensity.clamp(0.0, 1.0);

    if (t >= 0.67) return _heatObservedHighColor;
    if (t >= 0.34) return _heatObservedMediumColor;
    return _heatObservedLowColor;
  }

  void _updateHeatmapCircles() {
    _circles.clear();

    _circles.addAll(_buildHeatCircles(_observedHeatmapPoints));
  }

  List<Circle> _buildHeatCircles(List<PredictedHeatmapPoint> points) {
    final List<Circle> circles = [];

    for (final point in points) {
      final double t = point.intensity.clamp(0.0, 1.0);
      final double baseRadius = 110 + (t * 160);
      circles.add(
        Circle(
          circleId: CircleId('obs_${point.lat}_${point.lng}'),
          center: LatLng(point.lat, point.lng),
          radius: baseRadius,
          fillColor: _heatColor(t).withOpacity(0.30),
          strokeWidth: 0,
        ),
      );
    }
    return circles;
  }

  // Removed _toggleHeatmapMode - using _setReportView and _setHeatmapView instead

  void _setHeatmapView() {
    setState(() {
      _isHeatmapMode = true;
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
      final clusterStatus = _pickClusterStatus(reportsAtPos);

      _markers.add(
        Marker(
          markerId: MarkerId('report_${firstReport.id}'),
          position: LatLng(firstReport.latitude, firstReport.longitude),
          infoWindow: InfoWindow(
            title: firstReport.title,
            snippet: '${reportsAtPos.length} báo cáo',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _statusToHue(clusterStatus),
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

  void _groupReportsByDistance(
    List<Report> reports, {
    double radiusInMeters = 40,
  }) {
    final List<List<Report>> groups = [];

    for (final report in reports) {
      bool added = false;

      for (final group in groups) {
        final center = group.first;
        final double dist = Geolocator.distanceBetween(
          center.latitude,
          center.longitude,
          report.latitude,
          report.longitude,
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

    final Map<String, List<Report>> grouped = {};
    for (int i = 0; i < groups.length; i++) {
      final center = groups[i].first;
      final key =
          '${center.latitude.toStringAsFixed(7)},${center.longitude.toStringAsFixed(7)}';
      grouped[key] = groups[i];
    }

    _groupedReports = grouped;
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
        return _reportPendingColor;
      case 'VERIFIED':
        return _reportVerifiedColor;
      case 'CLEANED':
        return _reportCleanedColor;
      case 'REJECTED':
        return _reportRejectedColor;
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

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isHeatmapMode
                ? 'Chú thích : Khu vực Điểm nóng'
                : 'Chú thích : Báo cáo rác thải',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          if (_isHeatmapMode) ...[
            _buildLegendItem(_heatObservedLowColor, 'Khu vực thấp'),
            _buildLegendItem(_heatObservedMediumColor, 'Khu vực trung bình'),
            _buildLegendItem(_heatObservedHighColor, 'Khu vực cao'),
          ] else ...[
            _buildLegendItem(_getStatusColor('VERIFIED'), 'Đã xác thực'),
            _buildLegendItem(_getStatusColor('CLEANED'), 'Đã dọn dẹp'),
          ],
        ],
      ),
    );
  }

  void _setReportView() {
    setState(() {
      _isHeatmapMode = false;
      _circles.clear();
      _observedHeatmapPoints.clear();
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
        imageOverlay: null,
        imageOverlayImg: null,
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

        const layers = ['goong-heat-circle'];
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
          case 'REJECTED':
            return '#9ca3af';
          default:
            return '#9ca3af';
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

      function ensureImageOverlay() {
        if (state.imageOverlay && state.imageOverlayImg) return;

        const overlay = document.createElement('div');
        overlay.style.position = 'fixed';
        overlay.style.inset = '0';
        overlay.style.background = 'rgba(0,0,0,0.82)';
        overlay.style.display = 'none';
        overlay.style.alignItems = 'center';
        overlay.style.justifyContent = 'center';
        overlay.style.flexDirection = 'column';
        overlay.style.padding = '12px';
        overlay.style.zIndex = '99999';

        const backBtn = document.createElement('button');
        backBtn.textContent = 'Trở về bản đồ';
        backBtn.style.border = 'none';
        backBtn.style.borderRadius = '8px';
        backBtn.style.padding = '10px 14px';
        backBtn.style.fontSize = '14px';
        backBtn.style.fontWeight = '600';
        backBtn.style.background = '#ffffff';
        backBtn.style.color = '#111827';
        backBtn.style.cursor = 'pointer';
        backBtn.style.marginBottom = '10px';
        backBtn.onclick = () => {
          overlay.style.display = 'none';
          if (state.imageOverlayImg) {
            state.imageOverlayImg.src = '';
          }
        };

        const img = document.createElement('img');
        img.style.maxWidth = '95vw';
        img.style.maxHeight = '78vh';
        img.style.objectFit = 'contain';
        img.style.borderRadius = '10px';
        img.style.boxShadow = '0 10px 25px rgba(0,0,0,0.35)';
        img.alt = 'Ảnh đính kèm báo cáo';

        const hint = document.createElement('div');
        hint.textContent = 'Nhấn "Trở về bản đồ" để đóng ảnh';
        hint.style.color = '#e5e7eb';
        hint.style.fontSize = '12px';
        hint.style.marginTop = '8px';

        overlay.appendChild(backBtn);
        overlay.appendChild(img);
        overlay.appendChild(hint);
        document.body.appendChild(overlay);

        state.imageOverlay = overlay;
        state.imageOverlayImg = img;
      }

      function openImageOverlay(url) {
        if (!url) return;
        ensureImageOverlay();
        if (!state.imageOverlay || !state.imageOverlayImg) return;
        state.imageOverlayImg.src = url;
        state.imageOverlay.style.display = 'flex';
      }

      function buildReportsPopupHtml(item) {
        const reports = Array.isArray(item.reports) && item.reports.length
          ? item.reports
          : [item];

        let html = '';
        html += '<div style="width:min(88vw,340px);max-height:52vh;overflow-y:auto;overflow-x:hidden;font-family:Arial,sans-serif;line-height:1.4;word-break:break-word;">';
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
            html += '<button type="button" class="goong-open-image" data-image-url="' + escapeHtml(imageUrl) + '" style="border:none;background:transparent;padding:0;font-size:12px;color:#2563eb;text-decoration:underline;cursor:pointer;">Xem ảnh đính kèm</button>';
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
              'REJECTED', '#9ca3af',
              '#9ca3af',
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

          state.map.getContainer().addEventListener('click', (event) => {
            const target = event && event.target ? event.target : null;
            if (!target || !target.classList || !target.classList.contains('goong-open-image')) {
              return;
            }

            event.preventDefault();
            const imageUrl = target.getAttribute('data-image-url') || '';
            openImageOverlay(imageUrl);
          });
        }
      }

      function renderHeat() {
        if (!state.heatPoints.length) return;

        if (state.map.getLayer('goong-reports-circle')) state.map.removeLayer('goong-reports-circle');
        if (state.map.getSource('goong-reports')) state.map.removeSource('goong-reports');

        const rankedPoints = state.heatPoints
          .map((point, index) => ({
            index,
            count: Number(point.count || point.reportCount || point.predictedCount7d || 0),
            intensity: Number(point.intensity || 0),
          }))
          .sort((a, b) => {
            if (b.count !== a.count) return b.count - a.count;
            return b.intensity - a.intensity;
          });

        const rankTierByIndex = new Map();
        const totalPoints = rankedPoints.length;
        rankedPoints.forEach((item, rank) => {
          const percentile = (rank + 1) / Math.max(totalPoints, 1);
          let tier = 'low';
          if (percentile <= 1 / 3) tier = 'high';
          else if (percentile <= 2 / 3) tier = 'medium';
          rankTierByIndex.set(item.index, tier);
        });

        const features = state.heatPoints.map((point, index) => {
          const intensity = Number(point.intensity || 0);
          const count = Number(point.count || point.reportCount || point.predictedCount7d || 0);

          const tier = totalPoints >= 3
            ? rankTierByIndex.get(index)
            : (intensity >= 0.67 ? 'high' : intensity >= 0.33 ? 'medium' : 'low');

          let clusterColor = '#f59e0b';
          if (tier === 'high') clusterColor = '#ef4444';
          else if (tier === 'medium') clusterColor = '#f59e0b';
          else clusterColor = '#22c55e';

          return {
            type: 'Feature',
            geometry: { type: 'Point', coordinates: [Number(point.lng), Number(point.lat)] },
            properties: {
              intensity,
              count,
              color: clusterColor,
            },
          };
        });

        const heatData = { type: 'FeatureCollection', features };
        const existingSource = state.map.getSource('goong-heat');
        if (existingSource && typeof existingSource.setData === 'function') {
          existingSource.setData(heatData);
        } else {
          if (state.map.getSource('goong-heat')) state.map.removeSource('goong-heat');
          state.map.addSource('goong-heat', {
            type: 'geojson',
            data: heatData,
          });
        }

        if (!state.map.getLayer('goong-heat-circle')) {
          state.map.addLayer({
            id: 'goong-heat-circle',
            type: 'circle',
            source: 'goong-heat',
            paint: {
              'circle-color': ['get', 'color'],
              'circle-radius': ['interpolate', ['linear'], ['get', 'intensity'], 0, 11, 1, 28],
              'circle-opacity': 0.72,
              'circle-stroke-color': '#ffffff',
              'circle-stroke-width': 2,
              'circle-stroke-opacity': 0.92,
            }
          });
        }
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
      extendBodyBehindAppBar: true,
      appBar: widget.hideAppBar
          ? null
          : AppBar(
              elevation: 0,
              scrolledUnderElevation: 0,
              shadowColor: Colors.transparent,
              forceMaterialTransparency: true,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              title: const Text(
                "Bản đồ báo cáo",
                style: TextStyle(color: Colors.black87, fontSize: 20),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.pushNamed(context, '/user_app'),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.my_location, color: Colors.black87),
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
          Positioned(top: 85, right: 6, child: _buildLegend()),
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
                  onPressed: _setHeatmapView,
                  backgroundColor: _isHeatmapMode ? Colors.orange : Colors.grey,
                  child: const Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                  ),
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
