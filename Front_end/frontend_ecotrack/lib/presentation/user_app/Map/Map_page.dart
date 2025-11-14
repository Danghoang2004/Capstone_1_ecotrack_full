import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:frontend_ecotrack/presentation/user_app/switch_tabs/App_bar.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'dart:convert';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final LatLng _center = LatLng(16.0471, 108.2068); // Đà Nẵng
  double _currentZoom = 12.0;
  List<Report> _reports = [];
  Timer? _timer; // Timer để tự động refresh

  @override
  void initState() {
    super.initState();
    _fetchReports();

    // Tự động refresh dữ liệu mỗi 10 giây
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchReports();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchReports() async {
    final url = Uri.parse('http://192.168.1.89:8080/api/reports');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final body = utf8.decode(response.bodyBytes);
      final List<dynamic> data = jsonDecode(body);

      setState(() {
        _reports = data.map((e) => Report.fromJson(e)).toList();
      });
    } else {
      debugPrint(' Lỗi tải dữ liệu: ${response.statusCode}');
    }
  }

  void _zoomIn() {
    setState(() {
      _currentZoom++;
      _mapController.move(_mapController.center, _currentZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoom--;
      _mapController.move(_mapController.center, _currentZoom);
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.red;
      case 'confirmed':
        return Colors.purple;
      case 'cleaned':
        return Colors.green;
      default:
        return Colors.orangeAccent;
    }
  }

  void _showReportDetails(Report r) {
    String imageUrl = '';
    if (r.imageUrl.isNotEmpty) {
      if (r.imageUrl.startsWith('http')) {
        imageUrl = r.imageUrl;
      } else if (r.imageUrl.startsWith('uploads/')) {
        imageUrl = 'http://192.168.1.89:8080/${r.imageUrl}';
      } else {
        imageUrl = 'http://192.168.1.89:8080/uploads/${r.imageUrl}';
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Mô tả : ${r.description}'),
                const SizedBox(height: 8),
                Text('Trạng thái : ${r.status}'),
                const SizedBox(height: 8),
                Text('Vĩ độ : ${r.latitude}'),
                const SizedBox(height: 8),
                Text('Kinh độ : ${r.longitude}'),
                if (imageUrl.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(center: _center, zoom: _currentZoom),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.mapapp',
              ),
              MarkerLayer(
                markers: _reports.map((r) {
                  return Marker(
                    point: LatLng(r.latitude, r.longitude),
                    width: 50,
                    height: 50,
                    builder: (context) => GestureDetector(
                      onTap: () => _showReportDetails(r),
                      child: Tooltip(
                        message:
                            "${r.title}\nTrạng thái: ${r.status.toUpperCase()}",
                        child: Icon(
                          Icons.location_pin,
                          color: _getStatusColor(r.status),
                          size: 40,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          // Chú thích màu
          Positioned(
            top: 5,
            left: 5,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Trạng thái",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  _LegendItem(color: Colors.red, label: "Chờ xử lý"),
                  _LegendItem(color: Colors.purple, label: "Đã xác nhận"),
                  _LegendItem(color: Colors.green, label: "Đã dọn"),
                ],
              ),
            ),
          ),
          // Nút zoom
          Positioned(
            bottom: 10,
            right: 7,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "zoomIn",
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add, color: Colors.black),
                ),
                const SizedBox(height: 3),
                FloatingActionButton(
                  heroTag: "zoomOut",
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 14),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class Report {
  final int id;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final String status;

  Report({
    required this.id,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.status,
  });

  factory Report.fromJson(Map<String, dynamic> j) {
    return Report(
      id: (j['id'] as num).toInt(),
      title: j['title'] ?? '',
      description: j['description'] ?? '',
      latitude: (j['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (j['longitude'] as num?)?.toDouble() ?? 0.0,
      imageUrl: j['imageUrl'] ?? j['image_url'] ?? '',
      status: j['status'] ?? '',
    );
  }
}
