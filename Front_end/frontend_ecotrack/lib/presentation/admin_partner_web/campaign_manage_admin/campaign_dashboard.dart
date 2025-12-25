import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/CampaignApi.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/data/models/DashboardStats.dart';
// Import ApiClient và các class của bạn ở đây

class CampaignDashboard extends StatefulWidget {
  const CampaignDashboard({super.key});

  @override
  State<CampaignDashboard> createState() => _CampaignDashboardState();
}

class _CampaignDashboardState extends State<CampaignDashboard> {
  late CampaignApi _repository;
  late Future<DashboardStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    // 1. Khởi tạo ApiClient dùng chung
    final apiClient = ApiClient(storage: const FlutterSecureStorage());

    // 2. Khởi tạo Repository
    _repository = CampaignApi(apiClient);

    // 3. Gọi dữ liệu
    _statsFuture = _repository.fetchStats();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardStats>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Lỗi: ${snapshot.error}"));
        }

        final data = snapshot.data!;

        return Row(
          children: [
            _item(
              "Đang diễn ra",
              "${data.activeCampaigns}",
              Icons.track_changes,
              Colors.green,
            ),
            const SizedBox(width: 16),
            _item(
              "Sắp diễn ra",
              "${data.upcomingCampaigns}",
              Icons.calendar_today,
              Colors.blue,
            ),
            const SizedBox(width: 16),
            _item(
              "Tổng người tham gia",
              "${data.totalParticipants}",
              Icons.group_outlined,
              Colors.purple,
            ),
            const SizedBox(width: 16),
            _item(
              "Tổng kinh phí",
              "${data.totalBudget.toStringAsFixed(0)} đ",
              Icons.monetization_on_outlined,
              Colors.orange,
            ),
          ],
        );
      },
    );
  }

  // Giữ nguyên hàm _item của bạn
  Widget _item(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
