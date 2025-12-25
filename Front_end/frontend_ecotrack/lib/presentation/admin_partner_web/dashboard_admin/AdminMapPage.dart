import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:frontend_ecotrack/core/services/ReportService.dart';
import 'package:latlong2/latlong.dart';
import 'package:frontend_ecotrack/data/models/report_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

class AdminMapPage extends StatefulWidget {
  const AdminMapPage({super.key});

  @override
  State<AdminMapPage> createState() => _AdminMapPageState();
}

class _AdminMapPageState extends State<AdminMapPage> {
  final MapController _mapController = MapController();
  final ReportServiceAdmin _reportService = ReportServiceAdmin();

  List<Report> _reports = [];

  // ================== [THÊM MỚI] ==================
  final Distance _distance = const Distance();
  List<List<Report>> _groupedReports = [];
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
            options: MapOptions(center: LatLng(16.0471, 108.2068), zoom: 12.0),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              ),

              // ======= [THAY MARKER THEO NHÓM] =======
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
