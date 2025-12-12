import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:frontend_ecotrack/data/models/Report.dart';
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

  List<Report> _reports = [];
  Timer? _timer;

  List<LatLng> _routePoints = [];
  bool _isRouting = false;

  LatLng? _myLocation;

  // [MỚI] Biến để quản lý luồng theo dõi vị trí
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _fetchReports();
    _timer = Timer.periodic(
      const Duration(seconds: 10),
          (_) => _fetchReports(),
    );

    // Gọi hàm theo dõi thời gian thực thay vì chỉ lấy 1 lần
    _startLiveTracking();
  }

  @override
  void dispose() {
    _timer?.cancel();
    // [QUAN TRỌNG] Hủy theo dõi GPS khi thoát màn hình để tiết kiệm pin
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  // --- [MỚI] HÀM THEO DÕI VỊ TRÍ REAL-TIME ---
  Future<void> _startLiveTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    // Cấu hình: Cập nhật mỗi khi di chuyển 10 mét
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    // Bắt đầu lắng nghe
    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {

      // Mỗi khi GPS thay đổi, code trong này sẽ chạy
      LatLng newPos = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _myLocation = newPos; // Cập nhật vị trí chấm xanh
        });

        // (Tùy chọn) Nếu muốn Camera luôn bám theo người dùng thì bỏ comment dòng dưới
        // _mapController.move(newPos, _mapController.zoom);
      }
    });

    // Lấy vị trí ngay lập tức lần đầu tiên để không phải chờ di chuyển mới hiện
    Position? firstPos = await Geolocator.getLastKnownPosition();
    if(firstPos != null && _myLocation == null) {
      setState(() {
        _myLocation = LatLng(firstPos.latitude, firstPos.longitude);
        _mapController.move(_myLocation!, 15);
      });
    }
  }

  // Hàm để bấm nút đưa camera về vị trí hiện tại
  void _centerOnMe() {
    if (_myLocation != null) {
      _mapController.move(_myLocation!, 16.0); // Zoom gần hơn chút
    }
  }
  // --------------------------------------------------

  Future<void> _fetchReports() async {
    final response = await apiClient.get("/api/public/reports");

    if (response.statusCode == 200) {
      final data = apiClient.decodeUtf8Json(response);
      if (mounted) {
        setState(() {
          _reports = (data as List).map((e) => Report.fromJson(e)).toList();
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

      // Cập nhật lại vị trí người dùng luôn cho chính xác
      setState(() {
        _myLocation = LatLng(userPos.latitude, userPos.longitude);
      });

      final String url =
          "http://router.project-osrm.org/route/v1/driving/${userPos.longitude},${userPos.latitude};$destLng,$destLat?overview=full&geometries=geojson";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> coords = data['routes'][0]['geometry']['coordinates'];

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $e")),
        );
      }
      setState(() {
        _isRouting = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING': return Colors.red;
      case 'VERIFIED': return Colors.orange;
      case 'CLEANED': return Colors.green;
      default: return Colors.grey;
    }
  }

  void _showReportDetails(Report r) {
    final String baseUrl = dotenv.env['API_BASE_URL']!;
    String imageUrl = r.imageUrl.startsWith("http")
        ? r.imageUrl
        : "$baseUrl${r.imageUrl}";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      r.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _getDirections(r.latitude, r.longitude);
                  },
                  icon: const Icon(Icons.directions, color: Colors.white),
                  label: const Text(
                    "Chỉ đường đến đây",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text("Mô tả: ${r.description}"),
              const SizedBox(height: 4),
              Text("Trạng thái: ${r.status}", style: TextStyle(color: _getStatusColor(r.status), fontWeight: FontWeight.bold)),

              if (r.imageUrl.isNotEmpty) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, size: 80),
                    ),
                  ),
                ),
              ],
            ],
          ),
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
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Chú thích",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
          ),
          const SizedBox(height: 6),
          _buildLegendItem(Colors.red, "Chờ duyệt"),
          const SizedBox(height: 4),
          _buildLegendItem(Colors.orange, "Đã xác thực"),
          const SizedBox(height: 4),
          _buildLegendItem(Colors.green, "Đã dọn dẹp"),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.hideAppBar
          ? null
          : PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: const Color(0xFF2E7D32),
          elevation: 0,
          title: const Text(
            "Bản đồ báo cáo",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/user_app', (route) => false),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.my_location, color: Colors.white),
              onPressed: _centerOnMe,
              tooltip: "Về vị trí của tôi",
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(center: _center, zoom: _currentZoom),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
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
                      builder: (_) => Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black26)]
                            ),
                            child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              MarkerLayer(
                markers: _reports.map((r) {
                  return Marker(
                    point: LatLng(r.latitude, r.longitude),
                    width: 50,
                    height: 50,
                    builder: (_) => GestureDetector(
                      onTap: () => _showReportDetails(r),
                      child: Icon(
                        Icons.location_pin,
                        color: _getStatusColor(r.status),
                        size: 40,
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text("Đang tìm đường..."),
                    ],
                  ),
                ),
              ),
            ),

          Positioned(
            top: 10,
            right: 10,
            child: _buildLegend(),
          ),
        ],
      ),

      floatingActionButton: _routePoints.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _routePoints = [];
          });
        },
        backgroundColor: Colors.red,
        icon: const Icon(Icons.close),
        label: const Text("Xóa đường"),
      )
          : null,
    );
  }
}