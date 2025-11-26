import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/core/services/user_service.dart';
import 'package:frontend_ecotrack/data/models/ProfileView.dart';
import 'package:frontend_ecotrack/presentation/user_app/switch_tabs/App_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final storage = const FlutterSecureStorage();
  final apiClient = ApiClient(storage: const FlutterSecureStorage());

  String username = '';
  int points = 0;
  int rank = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final userService = UserService();
      final ProfileView profile = await userService.getProfileView();

      setState(() {
        username = profile.username ?? "Người dùng";
        points = profile.points ?? 0;
        rank = profile.rank ?? 0;
        isLoading = false;
      });
    } catch (e) {
      print("Lỗi tải profile: $e");
      setState(() {
        username = "Không xác định";
        points = 0;
        rank = 0;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFF8),
      appBar: CustomAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Greeting Card ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Xin chào, $username ! ",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          "$points điểm",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          "$rank hạng",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.eco_outlined, color: Colors.white),
                      label: const Text(
                        "Eco Member",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade800,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- Quick Actions ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _quickAction(
                    icon: Icons.camera_alt_outlined,
                    label: "Báo cáo rác \n Chụp ảnh & GPS",
                    onTap: () {
                      Navigator.pushNamed(context, '/report');
                    },
                  ),
                  _quickAction(
                    icon: Icons.qr_code_scanner,
                    label: "Check-in \n Quét QR chiến dịch",
                    onTap: () {
                      Navigator.pushNamed(context, '/QR_check');
                    },
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // --- Chiến dịch đang diễn ra ---
              _sectionHeader("Chiến dịch đang diễn ra", onTap: () {}),
              const SizedBox(height: 1),

              _campaignItem(
                image: 'assets/images/park_cleanup.jpg',
                title: 'Dọn rác bãi biển Đà Nẵng',
                date: '10/12/2025 08:00 - 11:00',
                joined: 199,
                distance: '1.2km',
              ),
              const SizedBox(height: 12),
              _campaignItem(
                image: 'assets/images/park_cleanup.jpg',
                title: 'Làm sạch công viên Tao Đàn',
                date: '15/07/2025 08:00 - 11:00',
                joined: 199,
                distance: '1.2km',
              ),

              const SizedBox(height: 20),

              // --- Bảng xếp hạng tuần ---
              _sectionHeader("Bảng Xếp Hạng Tuần", onTap: () {}),
              const SizedBox(height: 1),
              _rankingBoard(),

              const SizedBox(height: 15),

              // --- Mini games / Rewards ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _featureCard(
                    Icons.videogame_asset_outlined,
                    "Mini Game",
                    "Quizz môi trường",
                  ),
                  _featureCard(
                    Icons.card_giftcard_outlined,
                    "Đổi thưởng",
                    "Coupon & Ưu đãi",
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // --- Hoạt động gần đây ---
              _sectionHeader("Hoạt Động Gần Đây", onTap: () {}),
              const SizedBox(height: 1),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Column(
                  children: [
                    _recentActivity(
                      "Báo cáo rác thành công",
                      "+50 điểm",
                      "6 giờ trước",
                    ),
                    _recentActivity(
                      "Tham gia chiến dịch",
                      "+50 điểm",
                      "6 giờ trước",
                    ),
                    _recentActivity(
                      "Đạt huy hiệu mới",
                      "+100 điểm",
                      "9 giờ trước",
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

  // ======== Widget Helpers ========

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 110,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade100),
            boxShadow: const [
              BoxShadow(
                color: Color(0x11000000),
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.green, size: 32),
              const SizedBox(height: 7),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(left: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 0),
            child: TextButton(
              onPressed: onTap,
              child: const Text("Xem tất cả"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _campaignItem({
    required String image,
    required String title,
    required String date,
    required int joined,
    required String distance,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.green.shade100),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 6.0, bottom: 6.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                image,
                width: 100,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    date,
                    style: const TextStyle(color: Colors.black54, fontSize: 10),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 10,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "$joined người tham gia",
                        style: const TextStyle(fontSize: 7),
                      ),
                      const Spacer(),
                      Text(
                        distance,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rankingBoard() {
    final List<Map<String, dynamic>> ranks = [
      {"name": "Dương Văn Hùng", "points": 2999},
      {"name": "Nguyễn Thị Lan", "points": 2950},
      {"name": "Trần Văn Bình", "points": 2890},
      {"name": "Đặng Văn Hùng", "points": 2690},
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        children: List.generate(ranks.length, (i) {
          final String name = ranks[i]["name"] as String;
          final int points = ranks[i]["points"] as int;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.green.shade700,
                  child: Text(
                    "${i + 1}",
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(name, style: const TextStyle(fontSize: 14)),
                ),
                Text(
                  "$points điểm",
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _featureCard(IconData icon, String title, String subtitle) {
    return Expanded(
      child: Container(
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.shade100),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.green, size: 30),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(subtitle, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _recentActivity(String title, String points, String time) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      subtitle: Text("$points • $time", style: const TextStyle(fontSize: 12)),
      leading: const Icon(Icons.check_circle_outline, color: Colors.green),
    );
  }
}
