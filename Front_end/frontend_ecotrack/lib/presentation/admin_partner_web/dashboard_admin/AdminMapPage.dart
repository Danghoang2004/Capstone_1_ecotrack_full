import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:frontend_ecotrack/core/services/ReportService.dart';

import 'package:latlong2/latlong.dart';
import 'package:frontend_ecotrack/data/models/report_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // [QUAN TRỌNG] Import để lấy IP
import 'package:intl/intl.dart'; // Import để format ngày giờ

class AdminMapPage extends StatefulWidget {
  const AdminMapPage({super.key});

  @override
  State<AdminMapPage> createState() => _AdminMapPageState();
}

class _AdminMapPageState extends State<AdminMapPage> {
  final MapController _mapController = MapController();
  final ReportService _reportService = ReportService();
  List<Report> _reports = [];

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
      }
    } catch (e) {
      debugPrint("Lỗi tải báo cáo: $e");
    }
  }

  // --- [LOGIC 1] Xử lý URL ảnh dựa trên .env ---
  String _buildImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith("http")) return path;

    // Lấy URL từ file .env, nếu không có thì dùng default
    final String baseUrl =
        dotenv.env['API_BASE_URL'] ?? "http://192.168.1.89:8080";
    return "$baseUrl$path";
  }

  // --- [LOGIC 2] Hiển thị Popup chi tiết ---
  void _showReportDetail(BuildContext context, Report report) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400, // Chiều rộng popup
          padding: const EdgeInsets.all(0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Ảnh Báo Cáo
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.network(
                      _buildImageUrl(report.imageUrl), // Gọi hàm xử lý ảnh
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey,
                            ),
                            Text("Không tải được ảnh"),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Nút đóng
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

              // 2. Thông tin chi tiết
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
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
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

                    Row(
                      children: [
                        const Icon(
                          Icons.category_outlined,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Loại rác: ${report.category}",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    const Text(
                      "Mô tả:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.description.isNotEmpty
                          ? report.description
                          : "Không có mô tả",
                      style: const TextStyle(color: Colors.black87),
                    ),

                    const SizedBox(height: 16),

                    // Tọa độ GPS
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "${report.latitude}, ${report.longitude}",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: LatLng(16.0471, 108.2068), // Tọa độ mặc định
              zoom: 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              ),
              MarkerLayer(
                markers: _reports.map((r) {
                  return Marker(
                    point: LatLng(r.latitude, r.longitude),
                    width: 45, // Tăng kích thước chút cho dễ bấm
                    height: 45,
                    builder: (ctx) => GestureDetector(
                      onTap: () {
                        // [GỌI HÀM HIỂN THỊ POPUP]
                        _showReportDetail(context, r);
                      },
                      child: Icon(
                        Icons.location_pin,
                        color: _getStatusColor(r.status),
                        size: 45,
                        shadows: const [
                          Shadow(
                            color: Colors.black38,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Chú thích bản đồ (Giữ nguyên)
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(blurRadius: 5, color: Colors.black26),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Chú thích",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  _legendItem(Colors.orange, "Chờ duyệt"),
                  _legendItem(Colors.blue, "Đã xác thực"),
                  _legendItem(Colors.green, "Đã dọn dẹp"),
                  _legendItem(Colors.red, "Từ chối"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Các Widget phụ trợ ---

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    switch (status) {
      case 'PENDING':
        color = Colors.orange;
        text = "Chờ duyệt";
        break;
      case 'VERIFIED':
        color = Colors.blue;
        text = "Đã xác thực";
        break;
      case 'CLEANED':
        color = Colors.green;
        text = "Đã dọn";
        break;
      case 'REJECTED':
        color = Colors.red;
        text = "Từ chối";
        break;
      default:
        color = Colors.grey;
        text = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.location_pin, color: color, size: 16),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'VERIFIED':
        return Colors.blue;
      case 'CLEANED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
