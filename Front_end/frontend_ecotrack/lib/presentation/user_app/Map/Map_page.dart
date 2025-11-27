import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:frontend_ecotrack/data/models/Report.dart';
import 'package:latlong2/latlong.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final LatLng _center = LatLng(16.0471, 108.2068); // Đà Nẵng
  double _currentZoom = 12.0;

  final ApiClient apiClient = ApiClient(storage: const FlutterSecureStorage());

  List<Report> _reports = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchReports();
    _timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _fetchReports(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchReports() async {
    final response = await apiClient.get("/api/public/reports");

    if (response.statusCode == 200) {
      final data = apiClient.decodeUtf8Json(response);

      setState(() {
        _reports = (data as List).map((e) => Report.fromJson(e)).toList();
      });
    } else {
      debugPrint("Lỗi tải báo cáo: ${response.statusCode}");
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

  void _showReportDetails(Report r) {
    const String baseUrl = "http://192.168.1.89:8080";

    String imageUrl = r.imageUrl.startsWith("http")
        ? r.imageUrl
        : "$baseUrl${r.imageUrl}";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.of(context).size.height * 0.6, // HIỂN THỊ 1/2 MÀN HÌNH
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
              Text(
                r.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text("Mô tả: ${r.description}"),
              Text("Trạng thái: ${r.status}"),
              Text("Vĩ độ: ${r.latitude}"),
              Text("Kinh độ: ${r.longitude}"),

              if (r.imageUrl.isNotEmpty) ...[
                const SizedBox(height: 16),

                /// ẢNH CÙNG KÍCH THƯỚC
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 200, // cố định chiều cao
                    fit: BoxFit.cover, // phóng vừa khung
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: const Color(0xFF2E7D32),
          elevation: 0,
          title: const Text(
            "Hiển thị báo cáo",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/user_app',
                (route) => false,
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline, color: Colors.white),
              onPressed: () {},
            ),
            const SizedBox(width: 4),
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
        ],
      ),
    );
  }
}
