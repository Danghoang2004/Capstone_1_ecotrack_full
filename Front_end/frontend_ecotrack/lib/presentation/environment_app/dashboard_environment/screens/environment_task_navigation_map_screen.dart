import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class EnvironmentTaskNavigationMapScreen extends StatefulWidget {
  final String taskTitle;
  final double destinationLat;
  final double destinationLong;

  const EnvironmentTaskNavigationMapScreen({
    super.key,
    required this.taskTitle,
    required this.destinationLat,
    required this.destinationLong,
  });

  @override
  State<EnvironmentTaskNavigationMapScreen> createState() =>
      _EnvironmentTaskNavigationMapScreenState();
}

class _EnvironmentTaskNavigationMapScreenState
    extends State<EnvironmentTaskNavigationMapScreen> {
  WebViewController? _controller;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _refreshDebounceTimer;

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  Position? _currentPosition;
  _RouteSummary? _routeSummary;

  @override
  void initState() {
    super.initState();
    _startLiveNavigation();
  }

  @override
  void dispose() {
    _refreshDebounceTimer?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startLiveNavigation() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _isRefreshing = false;
    });

    try {
      final firstPosition = await _resolveCurrentLocation();
      await _renderRouteForPosition(firstPosition, forceReload: true);
      _listenToLocationChanges(firstPosition);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = _friendlyError(e);
      });
    }
  }

  void _listenToLocationChanges(Position seedPosition) {
    _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 12,
          ),
        ).listen(
          (position) {
            final previous = _currentPosition ?? seedPosition;
            final movedMeters = Geolocator.distanceBetween(
              previous.latitude,
              previous.longitude,
              position.latitude,
              position.longitude,
            );

            if (movedMeters < 12) {
              return;
            }

            _refreshDebounceTimer?.cancel();
            _refreshDebounceTimer = Timer(const Duration(seconds: 2), () {
              _renderRouteForPosition(position, forceReload: false);
            });
          },
          onError: (_) {
            // Keep last rendered route visible if live tracking temporarily fails.
          },
        );
  }

  Future<void> _renderRouteForPosition(
    Position currentPosition, {
    required bool forceReload,
  }) async {
    if (!mounted) return;

    setState(() {
      _currentPosition = currentPosition;
      _isRefreshing = !forceReload;
      _error = null;
    });

    try {
      final mapKey = _resolveGoongMapKey();
      final directionsKey = _resolveGoongDirectionsKey();
      final routePlan = await _fetchGoongRoute(
        apiKey: directionsKey,
        originLat: currentPosition.latitude,
        originLong: currentPosition.longitude,
        destLat: widget.destinationLat,
        destLong: widget.destinationLong,
      );

      final html = _buildGoongMapHtml(
        apiKey: mapKey,
        originLat: currentPosition.latitude,
        originLong: currentPosition.longitude,
        destLat: widget.destinationLat,
        destLong: widget.destinationLong,
        routePoints: routePlan.routePoints,
        distanceKmText: routePlan.distanceKmText,
        durationText: routePlan.durationText,
        liveUpdateText: routePlan.routePoints.isNotEmpty
            ? 'Đường đi được làm mới theo vị trí realtime.'
            : 'Không lấy được route chi tiết, đang hiển thị tuyến tạm thời.',
      );

      _controller ??= _createController();
      await _controller!.loadHtmlString(html);

      if (!mounted) return;
      setState(() {
        _routeSummary = routePlan;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _error = _friendlyError(e);
      });
    }
  }

  WebViewController _createController() {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _isLoading = false);
          },
        ),
      );
  }

  Future<Position> _resolveCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('GPS đang tắt. Vui lòng bật dịch vụ vị trí.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Không có quyền vị trí để mở chỉ đường.');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  }

  String _resolveGoongMapKey() {
    final key = dotenv.env['GOONG_MAP_KEY'] ?? '';
    if (key.trim().isEmpty) {
      throw Exception('Thiếu GOONG_MAP_KEY trong file .env');
    }
    return key.trim();
  }

  String _resolveGoongDirectionsKey() {
    final key =
        dotenv.env['GOONG_API_KEY'] ?? dotenv.env['GOONG_MAP_KEY'] ?? '';
    if (key.trim().isEmpty) {
      throw Exception('Thiếu GOONG_API_KEY hoặc GOONG_MAP_KEY trong file .env');
    }
    return key.trim();
  }

  Future<_RouteSummary> _fetchGoongRoute({
    required String apiKey,
    required double originLat,
    required double originLong,
    required double destLat,
    required double destLong,
  }) async {
    final uri = Uri.parse(
      'https://rsapi.goong.io/Direction?origin=$originLat,$originLong&destination=$destLat,$destLong&vehicle=car&api_key=$apiKey',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      return _RouteSummary(
        routePoints: const [],
        distanceKmText: _distanceFallbackKm(
          originLat,
          originLong,
          destLat,
          destLong,
        ),
        durationText: 'Không lấy được ETA',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return _RouteSummary(
        routePoints: const [],
        distanceKmText: _distanceFallbackKm(
          originLat,
          originLong,
          destLat,
          destLong,
        ),
        durationText: 'Không lấy được ETA',
      );
    }

    final routes = decoded['routes'];
    if (routes is! List || routes.isEmpty) {
      return _RouteSummary(
        routePoints: const [],
        distanceKmText: _distanceFallbackKm(
          originLat,
          originLong,
          destLat,
          destLong,
        ),
        durationText: 'Không lấy được ETA',
      );
    }

    final firstRoute = routes.first;
    if (firstRoute is! Map<String, dynamic>) {
      return _RouteSummary(
        routePoints: const [],
        distanceKmText: _distanceFallbackKm(
          originLat,
          originLong,
          destLat,
          destLong,
        ),
        durationText: 'Không lấy được ETA',
      );
    }

    final points = _extractRoutePoints(firstRoute);

    final distanceMeters =
        _extractDistanceMeters(firstRoute) ??
        _extractDistanceMetersFromResponse(decoded) ??
        Geolocator.distanceBetween(originLat, originLong, destLat, destLong);

    final durationText =
        _extractDurationText(firstRoute) ??
        _extractDurationTextFromResponse(decoded) ??
        'Không lấy được ETA';

    return _RouteSummary(
      routePoints: points,
      distanceKmText: _formatDistanceKm(distanceMeters),
      durationText: durationText,
    );
  }

  List<_RoutePoint> _extractRoutePoints(Map<String, dynamic> route) {
    final encodedCandidates = <String>[];
    final seen = <String>{};
    List<_RoutePoint>? coordinatePoints;

    void addCandidate(dynamic value) {
      if (value == null) return;
      final text = value.toString().trim();
      if (text.isEmpty) return;
      if (seen.add(text)) {
        encodedCandidates.add(text);
      }
    }

    void walk(dynamic value) {
      if (coordinatePoints != null) return;

      if (value is Map) {
        final map = value.cast<dynamic, dynamic>();
        final keysToCheck = [
          'overview_polyline',
          'polyline',
          'points',
          'overview_path',
          'path',
          'routes',
          'legs',
          'steps',
        ];

        for (final key in keysToCheck) {
          walk(map[key]);
          if (coordinatePoints != null) return;
        }

        for (final entry in map.entries) {
          walk(entry.value);
          if (coordinatePoints != null) return;
        }
      } else if (value is List) {
        if (_looksLikeCoordinateList(value)) {
          coordinatePoints = _pointsFromCoordinateList(value);
          return;
        }

        for (final item in value) {
          walk(item);
          if (coordinatePoints != null) return;
        }
      } else if (value is String) {
        addCandidate(value);
      }
    }

    walk(route);

    if (coordinatePoints != null && coordinatePoints!.length > 1) {
      return coordinatePoints!;
    }

    for (final encoded in encodedCandidates) {
      final decoded = _decodePolyline(encoded);
      if (decoded.length > 1) {
        return decoded;
      }
    }

    return const [];
  }

  bool _looksLikeCoordinateList(List<dynamic> value) {
    if (value.length < 2) return false;
    return value.every((item) {
      if (item is List && item.length >= 2) {
        return item[0] is num && item[1] is num;
      }
      return false;
    });
  }

  List<_RoutePoint> _pointsFromCoordinateList(List<dynamic> value) {
    final points = <_RoutePoint>[];
    for (final item in value) {
      if (item is List && item.length >= 2) {
        final lng = item[0];
        final lat = item[1];
        if (lng is num && lat is num) {
          points.add(_RoutePoint(lat.toDouble(), lng.toDouble()));
        }
      }
    }
    return points;
  }

  double? _extractDistanceMeters(Map<String, dynamic> route) {
    final legs = route['legs'];
    if (legs is! List || legs.isEmpty) return null;

    final firstLeg = legs.first;
    if (firstLeg is! Map<String, dynamic>) return null;

    final distance = firstLeg['distance'];
    if (distance is Map<String, dynamic>) {
      final meters = distance['value'];
      if (meters is num) return meters.toDouble();
    }

    return _parseDistanceText(distance);
  }

  double? _extractDistanceMetersFromResponse(Map<String, dynamic> response) {
    final routes = response['routes'];
    if (routes is! List || routes.isEmpty) return null;
    final firstRoute = routes.first;
    if (firstRoute is! Map<String, dynamic>) return null;
    return _extractDistanceMeters(firstRoute);
  }

  String? _extractDurationText(Map<String, dynamic> route) {
    final legs = route['legs'];
    if (legs is! List || legs.isEmpty) return null;

    final firstLeg = legs.first;
    if (firstLeg is! Map<String, dynamic>) return null;

    final duration = firstLeg['duration'];
    if (duration is Map<String, dynamic>) {
      final text = duration['text']?.toString();
      if (text != null && text.isNotEmpty) return text;
    }
    return duration?.toString();
  }

  String? _extractDurationTextFromResponse(Map<String, dynamic> response) {
    final routes = response['routes'];
    if (routes is! List || routes.isEmpty) return null;
    final firstRoute = routes.first;
    if (firstRoute is! Map<String, dynamic>) return null;
    return _extractDurationText(firstRoute);
  }

  double? _parseDistanceText(dynamic distanceValue) {
    if (distanceValue is Map<String, dynamic>) {
      final meters = distanceValue['value'];
      if (meters is num) return meters.toDouble();
      final text = distanceValue['text']?.toString();
      if (text != null) return _parseDistanceText(text);
    }

    final text = distanceValue?.toString() ?? '';
    if (text.isEmpty) return null;

    final normalized = text.replaceAll(',', '.').trim().toLowerCase();
    final numberMatch = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(normalized);
    if (numberMatch == null) return null;

    final number = double.tryParse(numberMatch.group(1)!);
    if (number == null) return null;

    if (normalized.contains('km')) {
      return number * 1000;
    }
    if (normalized.contains('m')) {
      return number;
    }
    return number;
  }

  String _distanceFallbackKm(
    double originLat,
    double originLong,
    double destLat,
    double destLong,
  ) {
    final meters = Geolocator.distanceBetween(
      originLat,
      originLong,
      destLat,
      destLong,
    );
    return _formatDistanceKm(meters);
  }

  String _formatDistanceKm(double meters) {
    final km = meters / 1000.0;
    if (km < 1) {
      return '${meters.round()} m';
    }
    return '${km.toStringAsFixed(km >= 10 ? 1 : 2)} km';
  }

  List<_RoutePoint> _decodePolyline(String encoded) {
    final points = <_RoutePoint>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(_RoutePoint(lat / 1e5, lng / 1e5));
    }

    return points;
  }

  String _buildGoongMapHtml({
    required String apiKey,
    required double originLat,
    required double originLong,
    required double destLat,
    required double destLong,
    required List<_RoutePoint> routePoints,
    required String distanceKmText,
    required String durationText,
    required String liveUpdateText,
  }) {
    final coordinates = routePoints
        .map((point) => [point.longitude, point.latitude])
        .toList();

    final routeJson = jsonEncode(coordinates);
    final safeTitle = widget.taskTitle
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('\n', ' ');
    final safeDistance = distanceKmText.replaceAll("'", "\\'");
    final safeDuration = durationText.replaceAll("'", "\\'");
    final safeLiveUpdate = liveUpdateText.replaceAll("'", "\\'");

    return '''
<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <link href="https://unpkg.com/maplibre-gl@4.7.1/dist/maplibre-gl.css" rel="stylesheet" />
  <script src="https://unpkg.com/maplibre-gl@4.7.1/dist/maplibre-gl.js"></script>
  <style>
    html, body, #map { margin: 0; padding: 0; width: 100%; height: 100%; background: #eef4ef; }
    .task-label {
      position: absolute;
      z-index: 2;
      left: 10px;
      top: 10px;
      right: 10px;
      background: rgba(255,255,255,0.96);
      border-radius: 12px;
      padding: 10px 12px;
      font-family: Arial, sans-serif;
      color: #1f2937;
      box-shadow: 0 2px 10px rgba(0,0,0,0.12);
    }
    .task-label .title { font-size: 13px; font-weight: 700; margin-bottom: 4px; }
    .task-label .meta { font-size: 12px; color: #374151; display: flex; flex-wrap: wrap; gap: 8px; }
    .pill {
      padding: 3px 8px;
      border-radius: 999px;
      background: #eef2ff;
      color: #1e40af;
      font-weight: 700;
    }
    .live {
      margin-top: 6px;
      font-size: 11px;
      color: #166534;
    }
  </style>
</head>
<body>
  <div class="task-label">
    <div class="title">$safeTitle</div>
    <div class="meta">
      <span class="pill">$safeDistance</span>
      <span class="pill">ETA: $safeDuration</span>
    </div>
    <div class="live">$safeLiveUpdate</div>
  </div>
  <div id="map"></div>
  <script>
    const origin = [$originLong, $originLat];
    const destination = [$destLong, $destLat];
    const routeCoordinates = $routeJson;

    const map = new maplibregl.Map({
      container: 'map',
      style: 'https://tiles.goong.io/assets/goong_map_web.json?api_key=$apiKey',
      center: destination,
      zoom: 14,
    });

    map.addControl(new maplibregl.NavigationControl(), 'bottom-right');

    map.on('load', () => {
      new maplibregl.Marker({ color: '#2563eb' })
        .setLngLat(origin)
        .setPopup(new maplibregl.Popup().setText('Vị trí hiện tại'))
        .addTo(map);

      new maplibregl.Marker({ color: '#16a34a' })
        .setLngLat(destination)
        .setPopup(new maplibregl.Popup().setText('Điểm task cần xử lý'))
        .addTo(map);

      if (Array.isArray(routeCoordinates) && routeCoordinates.length > 1) {
        map.addSource('task-route', {
          type: 'geojson',
          data: {
            type: 'Feature',
            geometry: {
              type: 'LineString',
              coordinates: routeCoordinates,
            },
          },
        });

        map.addLayer({
          id: 'task-route-line',
          type: 'line',
          source: 'task-route',
          layout: {
            'line-cap': 'round',
            'line-join': 'round',
          },
          paint: {
            'line-color': '#15803d',
            'line-width': 5,
            'line-opacity': 0.9,
          },
        });

        const bounds = routeCoordinates.reduce(
          (bounds, coord) => bounds.extend(coord),
          new maplibregl.LngLatBounds(routeCoordinates[0], routeCoordinates[0]),
        );
        map.fitBounds(bounds, { padding: 56, maxZoom: 16 });
      } else {
        const bounds = new maplibregl.LngLatBounds();
        bounds.extend(origin);
        bounds.extend(destination);
        map.fitBounds(bounds, { padding: 64, maxZoom: 16 });

        const warning = document.createElement('div');
        warning.textContent = 'Không lấy được polyline chi tiết từ Goong, chỉ hiển thị marker điểm đi/đến.';
        warning.style.position = 'absolute';
        warning.style.left = '10px';
        warning.style.right = '10px';
        warning.style.bottom = '12px';
        warning.style.zIndex = '2';
        warning.style.padding = '10px 12px';
        warning.style.borderRadius = '10px';
        warning.style.background = 'rgba(255, 245, 230, 0.96)';
        warning.style.color = '#9a3412';
        warning.style.fontFamily = 'Arial, sans-serif';
        warning.style.fontSize = '12px';
        warning.style.boxShadow = '0 2px 10px rgba(0,0,0,0.10)';
        document.body.appendChild(warning);
      }
    });
  </script>
</body>
</html>
''';
  }

  String _friendlyError(Object error) {
    final text = error.toString().replaceFirst('Exception: ', '');
    if (text.contains('permission') || text.contains('quyền')) {
      return 'Ứng dụng chưa có quyền vị trí. Vui lòng cấp quyền rồi thử lại.';
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Chỉ đường tới điểm xử lý'),
        actions: [
          IconButton(
            tooltip: 'Làm mới route',
            onPressed: _currentPosition == null
                ? null
                : () => _renderRouteForPosition(
                    _currentPosition!,
                    forceReload: true,
                  ),
            icon: const Icon(Icons.refresh, color: Color(0xFF5EAC24)),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.taskTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  _routeSummary == null
                      ? 'Đang lấy route Goong...'
                      : 'Quãng đường: ${_routeSummary!.distanceKmText}  •  ETA: ${_routeSummary!.durationText}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  _isRefreshing
                      ? 'Đang cập nhật theo vị trí realtime...'
                      : 'Route sẽ tự làm mới khi nhân viên di chuyển.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF166534),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                if (_controller != null)
                  WebViewWidget(controller: _controller!),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
                if (_error != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFFB91C1C)),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _startLiveNavigation,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Thử lại'),
                          ),
                        ],
                      ),
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

class _RoutePoint {
  final double latitude;
  final double longitude;

  const _RoutePoint(this.latitude, this.longitude);
}

class _RouteSummary {
  final List<_RoutePoint> routePoints;
  final String distanceKmText;
  final String durationText;

  const _RouteSummary({
    required this.routePoints,
    required this.distanceKmText,
    required this.durationText,
  });
}
