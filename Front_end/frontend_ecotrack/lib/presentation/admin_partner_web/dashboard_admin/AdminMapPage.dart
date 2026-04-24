import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:js' as js;
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend_ecotrack/core/services/ReportService.dart';
import 'package:frontend_ecotrack/core/services/hotspot_service.dart';
import 'package:frontend_ecotrack/data/models/hotspot_models.dart';
import 'package:frontend_ecotrack/data/models/report_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class AdminMapPage extends StatefulWidget {
  const AdminMapPage({super.key});

  @override
  State<AdminMapPage> createState() => _AdminMapPageState();
}

class _AdminMapPageState extends State<AdminMapPage> {
  static const String _initialModeReports = 'reports';
  static const String _initialModeObserved = 'heat_observed';
  static const String _initialModePredicted = 'heat_predicted';
  static const double _initialLat = 16.0471;
  static const double _initialLng = 108.2068;
  static const double _initialZoom = 16.2;
  static const int _popupDetailLimit = 5;
  static const int _popupDescriptionLimit = 60;
  static const int _maxPredictedPointsOnMap = 30;
  static const Set<String> _mapVisibleReportStatuses = {'VERIFIED', 'CLEANED'};
  static const Color _reportPendingColor = Color(0xFFF44336);
  static const Color _reportVerifiedColor = Color(0xFFFB8C00);
  static const Color _reportCleanedColor = Color(0xFF2E7D32);
  static const Color _reportRejectedColor = Color(0xFF9CA3AF);
  static const Color _heatObservedLowColor = Color(0xFF22C55E);
  static const Color _heatObservedMediumColor = Color(0xFFF59E0B);
  static const Color _heatObservedHighColor = Color(0xFFEF4444);
  static const Color _heatPredictedLowColor = Color(0xFF06B6D4);
  static const Color _heatPredictedMediumColor = Color(0xFF8B5CF6);
  static const Color _heatPredictedHighColor = Color(0xFFEF4444);

  final ReportServiceAdmin _reportService = ReportServiceAdmin();
  final HotspotService _hotspotService = HotspotService();

  final List<Report> _reports = [];
  List<List<Report>> _groupedReports = [];
  List<PredictedHeatmapPoint> _observedHeatmapPoints = [];
  List<PredictedHeatmapPoint> _predictedHeatmapPoints = [];

  Timer? _reportsPollingTimer;
  Timer? _hotspotDebounce;
  Timer? _mapInitRetryTimer;
  Timer? _mapReadyPoller;
  bool _isLoadingReports = true;
  bool _isLoadingHotspots = false;
  bool _isHeatmapMode = false;
  bool _showPredictedHotspots = false;
  bool _mapReady = false;
  bool _mapInitializing = false;
  bool _mapInitialized = false;
  String _mapStatus = 'Đang khởi tạo Goong map...';

  late final String _viewType;
  html.DivElement? _mapContainer;

  @override
  void initState() {
    super.initState();
    _viewType = 'goong-admin-map-${DateTime.now().microsecondsSinceEpoch}';
    _registerViewFactory();
    _fetchReports();
    _startReportsPolling();
    _validateGoongApiKey();
  }

  void _startReportsPolling() {
    _reportsPollingTimer?.cancel();
    _reportsPollingTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _fetchReports();
      if (_isHeatmapMode) {
        _hotspotDebounce?.cancel();
        _hotspotDebounce = Timer(const Duration(milliseconds: 250), () {
          if (mounted && _isHeatmapMode) {
            _fetchHotspots();
          }
        });
      }
    });
  }

  void _stopReportsPolling() {
    _reportsPollingTimer?.cancel();
    _reportsPollingTimer = null;
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

  void _registerViewFactory() {
    ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final container = html.DivElement()
        ..id = _viewType
        ..className = 'goong-map-host'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.position = 'absolute'
        ..style.top = '0'
        ..style.right = '0'
        ..style.bottom = '0'
        ..style.left = '0'
        ..style.backgroundColor = '#eef4ef';

      _mapContainer = container;
      return container;
    });
  }

  void _onPlatformViewCreated(int viewId) {
    _mapContainer ??=
        html.document.getElementById(_viewType) as html.DivElement?;
    _waitForContainerAndInit();
  }

  void _waitForContainerAndInit() {
    int attempts = 0;

    void check() {
      if (!mounted || _mapInitialized || _mapInitializing) {
        return;
      }

      final container = _mapContainer;
      final ready =
          container != null &&
          container.isConnected == true &&
          container.clientWidth > 0 &&
          container.clientHeight > 0;

      if (ready) {
        _initializeGoongMap();
        return;
      }

      attempts += 1;
      if (attempts == 30) {
        _setMapStatus('Đang chờ container Goong map sẵn sàng...');
        _logMapTrace(
          'attach',
          'Container still not ready after 30 retries, continue waiting',
        );
      }

      Future.delayed(const Duration(milliseconds: 100), check);
    }

    check();
  }

  Future<void> _initializeGoongMap() async {
    if (!kIsWeb || _mapInitializing || _mapInitialized) {
      return;
    }

    _mapInitializing = true;

    try {
      final String mapKey = dotenv.env['GOONG_MAP_KEY'] ?? '';
      if (mapKey.isEmpty) {
        _setMapStatus('Thiếu GOONG_MAP_KEY trong .env');
        _logMapTrace('init', 'Missing GOONG_MAP_KEY');
        return;
      }

      final container = _mapContainer;
      if (container == null || container.isConnected != true) {
        _logMapTrace('init', 'container is null or not connected');
        _scheduleMapInitRetry('Chưa sẵn sàng container cho Goong map');
        return;
      }

      if (container.clientWidth <= 0 || container.clientHeight <= 0) {
        _logMapTrace(
          'init',
          'container size is not ready yet (${container.clientWidth}x${container.clientHeight})',
        );
        _scheduleMapInitRetry('Đang chờ kích thước container Goong map...');
        return;
      }

      final styleUrl =
          'https://tiles.goong.io/assets/goong_map_web.json?api_key=$mapKey';
      final geocodeApiKey = dotenv.env['GOONG_API_KEY'] ?? '';

      _mapReadyPoller?.cancel();

      _mapReady = false;
      _setMapStatus('Đang tải Goong map...');
      _logMapTrace(
        'init',
        'starting with center=($_initialLng,$_initialLat) zoom=$_initialZoom',
      );

      if (!_hasGoongMapHostMethod('goongAdminMapInit')) {
        _logMapTrace('init', 'goongAdminMapInit is not available yet');
        _scheduleMapInitRetry('Chưa nạp được Goong map host');
        return;
      }

      _startGoongMapInit(
        container: container,
        styleUrl: styleUrl,
        lng: _initialLng,
        lat: _initialLat,
        zoom: _initialZoom,
        geocodeApiKey: geocodeApiKey,
      );

      _mapReadyPoller = Timer.periodic(const Duration(milliseconds: 150), (
        timer,
      ) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        try {
          if (!_hasGoongMapHostMethod('goongAdminMapIsReady')) {
            timer.cancel();
            _logMapTrace('poll', 'goongAdminMapIsReady is not available yet');
            _scheduleMapInitRetry('Chưa nạp được Goong map host');
            return;
          }

          final isReady = js.context.callMethod(
            'goongAdminMapIsReady',
            const [],
          );

          if (isReady == true) {
            timer.cancel();
            _mapReady = true;
            _mapInitialized = true;
            _setMapStatus('Goong map đã sẵn sàng');
            _logMapTrace('ready', 'Goong map reported ready by JS host');
            setState(() {});
            _syncMapState();
            return;
          }

          final error = _hasGoongMapHostMethod('goongAdminMapLastError')
              ? js.context.callMethod('goongAdminMapLastError', const [])
              : null;
          if (error != null && error.toString().isNotEmpty) {
            _setMapStatus('Goong map chưa tải xong: $error');
            _logMapTrace('poll', error.toString());
            _logMapTrace('poll', _readGoongMapDiagnostics());
            setState(() {});
          }
        } catch (e) {
          timer.cancel();
          _logMapTrace('poll', 'status poll failed: $e');
        }
      });

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _logMapTrace('init', 'Goong map init failed: $e');
      if (mounted) {
        _setMapStatus('Không thể khởi tạo Goong map');
      }
    } finally {
      _mapInitializing = false;
    }
  }

  void _startGoongMapInit({
    required html.DivElement container,
    required String styleUrl,
    required double lng,
    required double lat,
    required double zoom,
    required String geocodeApiKey,
  }) {
    Timer.run(() {
      if (!mounted) {
        return;
      }

      try {
        _logMapTrace(
          'host-call',
          'Calling goongAdminMapInit with lng=$lng, lat=$lat, zoom=$zoom',
        );
        js.context.callMethod('goongAdminMapInit', [
          container,
          styleUrl,
          lng,
          lat,
          zoom,
          geocodeApiKey,
        ]);
        _logMapTrace('host-init', 'goongAdminMapInit invoked successfully');
        _logMapTrace('host-init', _readGoongMapDiagnostics());
      } catch (e) {
        _logMapTrace('host-init', 'goongAdminMapInit call failed: $e');
        if (mounted) {
          _setMapStatus('Không thể gọi init của Goong map');
          _scheduleMapInitRetry('Chưa thể gọi Goong map host, sẽ thử lại');
        }
      }
    });
  }

  void _scheduleMapInitRetry(String status) {
    if (!mounted || _mapReady || _mapInitialized) {
      return;
    }

    _mapStatus = status;
    _logMapTrace('retry', status);
    setState(() {});

    _mapInitRetryTimer?.cancel();
    _mapInitRetryTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted && !_mapReady && !_mapInitialized && !_mapInitializing) {
        _initializeGoongMap();
      }
    });
  }

  void _setMapStatus(String status) {
    _mapStatus = status;
    if (mounted) {
      setState(() {});
    }
  }

  void _logMapTrace(String stage, String message) {
    debugPrint('[GoongMap][$stage] $message');
  }

  bool _hasGoongMapHostMethod(String methodName) {
    try {
      return js.context.hasProperty(methodName) == true;
    } catch (_) {
      return false;
    }
  }

  String _readGoongMapDiagnostics() {
    try {
      if (_hasGoongMapHostMethod('goongAdminMapDiagnostics')) {
        final diagnostics = js.context.callMethod(
          'goongAdminMapDiagnostics',
          const [],
        );
        return '[GoongMap][diagnostics] ${diagnostics.toString()}';
      }
    } catch (e) {
      return '[GoongMap][diagnostics] failed: $e';
    }

    return '[GoongMap][diagnostics] unavailable';
  }

  Future<void> _validateGoongApiKey() async {
    final String apiKey = dotenv.env['GOONG_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      debugPrint('GOONG_API_KEY is empty. Goong API calls are disabled.');
      return;
    }

    try {
      final uri = Uri.parse(
        'https://rsapi.goong.io/Geocode?address=Da%20Nang&api_key=$apiKey',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        debugPrint('Goong API key is valid. NPS/API call is working.');
      } else {
        debugPrint(
          'Goong API check failed: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Goong API check error: $e');
    }
  }

  Future<void> _fetchReports() async {
    try {
      final data = await _reportService.fetchAllReports();
      if (!mounted) return;

      setState(() {
        _reports
          ..clear()
          ..addAll(data);
        _groupReportsByDistance(data, radiusInMeters: 40);
        _isLoadingReports = false;
      });

      _syncMapState();
    } catch (e) {
      debugPrint('Lỗi tải báo cáo: $e');
      if (mounted) {
        setState(() => _isLoadingReports = false);
      }
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

    _groupedReports = groups;
  }

  @override
  void dispose() {
    _stopReportsPolling();
    _hotspotDebounce?.cancel();
    _mapInitRetryTimer?.cancel();
    _mapReadyPoller?.cancel();
    if (kIsWeb && js.context['goongAdminMapDispose'] != null) {
      try {
        js.context.callMethod('goongAdminMapDispose', const []);
      } catch (_) {
        // ignore
      }
    }
    super.dispose();
  }

  void _syncMapState() {
    if (!kIsWeb || !_mapReady) {
      debugPrint(
        '[AdminMapPage._syncMapState] Early return: kIsWeb=$kIsWeb, _mapReady=$_mapReady',
      );
      return;
    }

    try {
      final mode = _isHeatmapMode
          ? (_showPredictedHotspots
                ? _initialModePredicted
                : _initialModeObserved)
          : _initialModeReports;

      debugPrint(
        '[AdminMapPage._syncMapState] Syncing mode=$mode, _reports.length=${_reports.length}, _groupedReports.length=${_groupedReports.length}',
      );
      js.context.callMethod('goongAdminMapSetMode', [mode]);

      if (mode == _initialModeReports) {
        final reportPayload = _buildReportPayload();
        debugPrint(
          '[AdminMapPage._syncMapState] Sending ${reportPayload.length} report clusters to JS',
        );
        js.context.callMethod('goongAdminMapSetReports', [
          jsonEncode(reportPayload),
        ]);
      } else {
        final points = _showPredictedHotspots
            ? _buildHeatPayload(_predictedHeatmapPoints, predicted: true)
            : _buildHeatPayload(_observedHeatmapPoints, predicted: false);
        debugPrint(
          '[AdminMapPage._syncMapState] Sending ${points.length} heat points (${_showPredictedHotspots ? "predicted" : "observed"}) to JS',
        );
        if (points.isNotEmpty) {
          debugPrint(
            '[AdminMapPage._syncMapState] First point: lat=${points.first['lat']}, lng=${points.first['lng']}, intensity=${points.first['intensity']}, count=${points.first['count']}',
          );
        }
        js.context.callMethod('goongAdminMapSetHeatPoints', [
          jsonEncode({
            'mode': _showPredictedHotspots ? 'heat_predicted' : 'heat_observed',
            'points': points,
          }),
        ]);
      }

      if (_hasGoongMapHostMethod('goongAdminMapLastError')) {
        final dynamic jsError = js.context.callMethod(
          'goongAdminMapLastError',
          const [],
        );
        final String errorText = jsError?.toString() ?? '';
        if (errorText.isNotEmpty) {
          if (mounted) {
            setState(() {
              _mapStatus = 'Lỗi hiển thị hotspot: $errorText';
            });
          } else {
            _mapStatus = 'Lỗi hiển thị hotspot: $errorText';
          }
        }
      }
    } catch (e) {
      debugPrint('Lỗi đồng bộ dữ liệu map: $e');
      if (mounted) {
        setState(() {
          _mapStatus = 'Lỗi đồng bộ dữ liệu map: $e';
        });
      } else {
        _mapStatus = 'Lỗi đồng bộ dữ liệu map: $e';
      }
    }
  }

  List<Map<String, dynamic>> _buildReportPayload() {
    final payload = _groupedReports
        .map((group) {
          // Keep only statuses that should be displayed on the map.
          final reportsInCluster =
              group
                  .where(
                    (r) => _mapVisibleReportStatuses.contains(
                      r.status.toUpperCase(),
                    ),
                  )
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (reportsInCluster.isEmpty) {
            return null;
          }

          final Report first = reportsInCluster.first;

          final visibleReports = reportsInCluster
              .take(_popupDetailLimit)
              .toList();
          final statusSummary = <String, int>{'VERIFIED': 0, 'CLEANED': 0};
          for (final report in reportsInCluster) {
            final key = report.status.toUpperCase();
            statusSummary[key] = (statusSummary[key] ?? 0) + 1;
          }

          return <String, dynamic>{
            'reportId': first.reportId,
            'title': first.title,
            'description': first.description,
            'imageUrl': first.imageUrl,
            'latitude': first.latitude,
            'longitude': first.longitude,
            'status': _pickClusterStatus(reportsInCluster),
            'category': first.category,
            'count': reportsInCluster.length,
            'overflowCount': reportsInCluster.length - visibleReports.length,
            'statusSummary': statusSummary,
            'reports': visibleReports
                .map(
                  (r) => <String, dynamic>{
                    'id': r.reportId,
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
    debugPrint(
      '[AdminMapPage._buildReportPayload] Built payload with ${payload.length} items',
    );
    return payload;
  }

  String _pickClusterStatus(List<Report> reports) {
    final statuses = reports.map((r) => r.status.toUpperCase()).toSet();
    // CLEANED has highest priority so a cleaned cluster turns green immediately.
    if (statuses.contains('CLEANED')) return 'CLEANED';
    if (statuses.contains('PENDING')) return 'PENDING';
    if (statuses.contains('VERIFIED')) return 'VERIFIED';
    if (reports.isEmpty) return 'UNKNOWN';
    return reports.first.status;
  }

  List<Map<String, dynamic>> _buildHeatPayload(
    List<PredictedHeatmapPoint> points, {
    required bool predicted,
  }) {
    final payload = points
        .map(
          (point) => <String, dynamic>{
            'lat': point.lat,
            'lng': point.lng,
            'intensity': point.intensity,
            'predictedCount7d': point.predictedCount7d,
            'reportCount': point.reportCount,
            'count': predicted ? point.predictedCount7d : point.reportCount,
            'predicted': predicted,
          },
        )
        .toList();

    debugPrint(
      '[AdminMapPage._buildHeatPayload] Built ${payload.length} items (predicted=$predicted)',
    );
    if (payload.isNotEmpty && payload.length <= 3) {
      debugPrint('[AdminMapPage._buildHeatPayload] Payload: $payload');
    }
    return payload;
  }

  void _setReportView() {
    setState(() {
      _isHeatmapMode = false;
      _showPredictedHotspots = false;
    });
    _syncMapState();
  }

  void _setHeatmapView({required bool predicted}) {
    setState(() {
      _isHeatmapMode = true;
      _showPredictedHotspots = predicted;
      _mapStatus = predicted
          ? 'Đang tải bản đồ dự đoán...'
          : 'Đang tải bản đồ hotspot...';
    });

    debugPrint(
      '[AdminMapPage._setHeatmapView] predicted=$predicted, _mapReady=$_mapReady, _mapInitialized=$_mapInitialized',
    );
    _fetchHotspots();
  }

  Future<void> _fetchHotspots() async {
    if (_isLoadingHotspots || !_isHeatmapMode) return;

    _isLoadingHotspots = true;
    try {
      final clusterFuture = _hotspotService.fetchAdminClusterInArea(
        minLat: 8.0,
        maxLat: 24.0,
        minLng: 102.0,
        maxLng: 110.0,
      );
      final predictFuture = _hotspotService.fetchAdminPredictionInArea(
        minLat: 8.0,
        maxLat: 24.0,
        minLng: 102.0,
        maxLng: 110.0,
      );

      final clusterResult = await clusterFuture;
      final predictResult = await predictFuture;

      debugPrint(
        '[AdminMapPage._fetchHotspots] cluster=${clusterResult.hotspots.length}, '
        'predictedZones=${predictResult.predictedHotspots7Days.length}, '
        'heatmapPoints=${predictResult.heatmapPoints.length}, '
        'clusterSuccess=${clusterResult.success}, predictedSuccess=${predictResult.success}',
      );

      if (!mounted) return;

      debugPrint('[AdminMapPage._fetchHotspots] Building observed points...');
      var observedPoints = _buildClusterDataPoints(
        clusterResult.hotspots,
        isPredicted: false,
      );
      debugPrint(
        '[AdminMapPage._fetchHotspots] Built ${observedPoints.length} observed heat points from ${clusterResult.hotspots.length} clusters',
      );

      if (observedPoints.isEmpty) {
        debugPrint(
          '[AdminMapPage._fetchHotspots] Observed points empty, building fallback from ${_reports.length} reports',
        );
        observedPoints = _buildFallbackHeatmapFromAllReports();
        debugPrint(
          '[AdminMapPage._fetchHotspots] Fallback generated ${observedPoints.length} points',
        );
      }

      debugPrint('[AdminMapPage._fetchHotspots] Building predicted points...');
      var predictedPoints = _buildClusterDataPoints(
        predictResult.predictedHotspots7Days,
        isPredicted: true,
      );

      if (predictedPoints.isEmpty && predictResult.heatmapPoints.isNotEmpty) {
        final nonZeroPredictedPoints = predictResult.heatmapPoints
            .where((point) => point.predictedCount7d > 0 || point.intensity > 0)
            .toList();
        debugPrint(
          '[AdminMapPage._fetchHotspots] Predicted zones empty, fallback candidates=${nonZeroPredictedPoints.length}',
        );

        if (nonZeroPredictedPoints.isNotEmpty) {
          nonZeroPredictedPoints.sort(
            (a, b) => b.predictedCount7d.compareTo(a.predictedCount7d),
          );
          predictedPoints = nonZeroPredictedPoints
              .take(_maxPredictedPointsOnMap)
              .toList();
        }
      }

      debugPrint(
        '[AdminMapPage._fetchHotspots] Using ${predictedPoints.length} predicted heat points (${predictResult.predictedHotspots7Days.isNotEmpty ? "from zones" : "from clustered heatmap fallback"})',
      );

      if (predictedPoints.length > _maxPredictedPointsOnMap) {
        predictedPoints.sort(
          (a, b) => b.predictedCount7d.compareTo(a.predictedCount7d),
        );
        predictedPoints = predictedPoints
            .take(_maxPredictedPointsOnMap)
            .toList();
        debugPrint(
          '[AdminMapPage._fetchHotspots] Trimmed predicted points to ${predictedPoints.length} for faster rendering',
        );
      }

      final String nextMapStatus;
      if (_showPredictedHotspots && predictedPoints.isEmpty) {
        nextMapStatus = 'Chưa có dữ liệu dự đoán để hiển thị';
      } else if (!_showPredictedHotspots && observedPoints.isEmpty) {
        nextMapStatus = 'Chưa có hotspot thực tế trong vùng hiện tại';
      } else {
        nextMapStatus = _showPredictedHotspots
            ? 'Hiển thị vùng dự đoán (${predictedPoints.length} điểm)'
            : 'Hiển thị hotspot thực tế (${observedPoints.length} điểm)';
      }

      setState(() {
        _observedHeatmapPoints = observedPoints;
        _predictedHeatmapPoints = predictedPoints;
        _mapStatus = nextMapStatus;
      });

      await Future<void>.delayed(Duration.zero);

      debugPrint(
        '[AdminMapPage._fetchHotspots] Calling _syncMapState with _mapReady=$_mapReady',
      );
      _syncMapState();
    } catch (e) {
      debugPrint('Lỗi fetch hotspot: $e');
      if (mounted) {
        setState(() {
          _mapStatus = 'Lỗi tải hotspot: $e';
        });
      } else {
        _mapStatus = 'Lỗi tải hotspot: $e';
      }
    } finally {
      _isLoadingHotspots = false;
    }
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
        predictedCount7d: count,
      );
    }).toList();
  }

  List<PredictedHeatmapPoint> _buildClusterDataPoints(
    List<HotspotZone> zones, {
    required bool isPredicted,
  }) {
    if (zones.isEmpty) return [];

    // Tính max count để normalize intensity
    final int maxCount = zones
        .map((z) {
          if (isPredicted) {
            return z.predictedCount7d ?? 0;
          } else {
            return z.reportCount;
          }
        })
        .fold<int>(1, (acc, value) => value > acc ? value : acc);

    return zones
        .map((zone) {
          final int count = isPredicted
              ? (zone.predictedCount7d ?? 0)
              : zone.reportCount;

          if (isPredicted && count <= 0) {
            return null;
          }

          return PredictedHeatmapPoint(
            lat: zone.centerLat,
            lng: zone.centerLng,
            intensity: (count / maxCount).clamp(0.0, 1.0),
            predictedCount7d: isPredicted ? count : 0,
            reportCount: !isPredicted ? count : 0,
          );
        })
        .whereType<PredictedHeatmapPoint>()
        .toList();
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
          (zone) => PredictedHeatmapPoint(
            lat: zone.centerLat,
            lng: zone.centerLng,
            intensity: (zone.reportCount / maxCount).clamp(0.0, 1.0),
            predictedCount7d: zone.reportCount,
          ),
        )
        .toList();
  }

  List<PredictedHeatmapPoint> _toPredictedHeatmapPointsFromZones(
    List<HotspotZone> zones,
  ) {
    if (zones.isEmpty) return [];

    final values = zones.map((z) {
      final predicted = z.predictedCount7d ?? 0;
      if (predicted > 0) return predicted;
      return z.reportCount;
    }).toList();

    final int maxCount = values.fold<int>(1, (acc, value) {
      return value > acc ? value : acc;
    });

    return zones
        .map((zone) {
          final count =
              zone.predictedCount7d != null && zone.predictedCount7d! > 0
              ? zone.predictedCount7d!
              : 0;
          if (count <= 0) {
            return null;
          }
          return PredictedHeatmapPoint(
            lat: zone.centerLat,
            lng: zone.centerLng,
            intensity: (count / maxCount).clamp(0.0, 1.0),
            predictedCount7d: count,
          );
        })
        .whereType<PredictedHeatmapPoint>()
        .toList();
  }

  Future<void> _zoomIn() async {
    if (!kIsWeb || !_mapReady) return;
    js.context.callMethod('goongAdminMapZoomIn', const []);
  }

  Future<void> _zoomOut() async {
    if (!kIsWeb || !_mapReady) return;
    js.context.callMethod('goongAdminMapZoomOut', const []);
  }

  Widget _buildMapStatusBanner() {
    final String mapKey = dotenv.env['GOONG_MAP_KEY'] ?? '';
    final bool hasVisibleError =
        _mapStatus.startsWith('Lỗi') ||
        _mapStatus.startsWith('Không thể') ||
        _mapStatus.startsWith('Chưa có dữ liệu') ||
        _mapStatus.startsWith('Chưa có hotspot');

    if (mapKey.isNotEmpty && _mapReady && !hasVisibleError) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasGoongKey = (dotenv.env['GOONG_MAP_KEY'] ?? '').isNotEmpty;

    return Scaffold(
      body: Container(
        color: const Color(0xFFeef4ef),
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: HtmlElementView(
                viewType: _viewType,
                onPlatformViewCreated: _onPlatformViewCreated,
              ),
            ),
            Positioned(top: 5, right: 12, child: _buildMapLegend()),
            Positioned(
              right: 4,
              bottom: 50,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    heroTag: 'admin_zoom_in',
                    mini: true,
                    onPressed: _zoomIn,
                    backgroundColor: const Color(0xFF2E7D32),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'admin_zoom_out',
                    mini: true,
                    onPressed: _zoomOut,
                    backgroundColor: const Color(0xFF2E7D32),
                    child: const Icon(Icons.remove, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'admin_mode_reports',
                    mini: true,
                    onPressed: _setReportView,
                    backgroundColor: !_isHeatmapMode
                        ? Colors.blue
                        : Colors.grey,
                    child: const Icon(Icons.list, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'admin_mode_hotspots',
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
                  FloatingActionButton(
                    heroTag: 'admin_mode_prediction',
                    mini: true,
                    onPressed: () => _setHeatmapView(predicted: true),
                    backgroundColor: _isHeatmapMode && _showPredictedHotspots
                        ? Colors.deepOrange
                        : Colors.grey,
                    child: const Icon(Icons.show_chart, color: Colors.white),
                  ),
                ],
              ),
            ),
            if (_isLoadingReports)
              const Positioned(
                top: 20,
                left: 12,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            if (_isLoadingHotspots)
              const Positioned(
                top: 20,
                right: 12,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            _buildMapStatusBanner(),
            if (!hasGoongKey)
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Text(
                    'Thiếu GOONG_MAP_KEY trong .env',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapLegend() {
    final String legendTitle;
    if (!_isHeatmapMode) {
      legendTitle = 'Chú thích: Báo cáo rác thải';
    } else if (_showPredictedHotspots) {
      legendTitle = 'Chú thích: Dự đoán điểm nóng 7 ngày tới';
    } else {
      legendTitle = 'Chú thích: Khu vực điểm nóng';
    }

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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            legendTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          if (_isHeatmapMode) ...[
            if (_showPredictedHotspots) ...[
              _legendItem('Dự đoán thấp', _heatPredictedLowColor),
              _legendItem('Dự đoán trung bình', _heatPredictedMediumColor),
              _legendItem('Dự đoán cao', _heatPredictedHighColor),
            ] else ...[
              _legendItem('Nhiệt thấp', _heatObservedLowColor),
              _legendItem('Nhiệt trung bình', _heatObservedMediumColor),
              _legendItem('Nhiệt cao / nguy cơ cao', _heatObservedHighColor),
            ],
          ] else ...[
            _legendItem('Đã xác thực', _getStatusColor('VERIFIED')),
            _legendItem('Đã dọn dẹp', _getStatusColor('CLEANED')),
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
}
