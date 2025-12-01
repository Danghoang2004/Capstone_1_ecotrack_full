import 'package:flutter/material.dart';

class UserProfile {
  final String name;
  final String email;
  final String avatarUrl;
  final int notificationCount;

  UserProfile({
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.notificationCount,
  });
}

class DashboardStat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  DashboardStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class Campaign {
  final String id;
  final String title;
  final String status;
  final String description;
  final String location;
  final String dateRange;
  final int currentParticipants;
  final int maxParticipants;
  final double currentBudget;
  final double totalBudget;
  final int points;
  final String organizer;

  Campaign({
    required this.id,
    required this.title,
    required this.status,
    required this.description,
    required this.location,
    required this.dateRange,
    required this.currentParticipants,
    required this.maxParticipants,
    required this.currentBudget,
    required this.totalBudget,
    required this.points,
    required this.organizer,
  });

  // Hàm hỗ trợ format tiền tệ
  String get formattedBudget =>
      "${totalBudget.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ";

  // Hàm lấy màu dựa trên trạng thái
  Color get statusColor {
    switch (status) {
      case "Đang diễn ra":
        return Colors.green;
      case "Sắp diễn ra":
        return Colors.blue;
      case "Đã hoàn thành":
        return Colors.grey;
      default:
        return Colors.black;
    }
  }
}

// 2. MOCK DATA

final UserProfile currentUser = UserProfile(
  name: "Admin Nguyễn",
  email: "admin@ecotrack.com",
  avatarUrl: "https://i.pravatar.cc/150?img=12",
  notificationCount: 5,
);

final List<DashboardStat> statsData = [
  DashboardStat(
    label: "Đang diễn ra",
    value: "1",
    icon: Icons.circle_outlined,
    color: Colors.green,
  ),
  DashboardStat(
    label: "Sắp diễn ra",
    value: "3",
    icon: Icons.calendar_today_outlined,
    color: Colors.blue,
  ),
  DashboardStat(
    label: "Tổng người tham gia",
    value: "190",
    icon: Icons.people_outline,
    color: Colors.purple,
  ),
  DashboardStat(
    label: "Tổng kinh phí",
    value: "68.000.000 đ",
    icon: Icons.attach_money,
    color: Colors.red,
  ),
];

final List<Campaign> campaignsData = [
  Campaign(
    id: "1",
    title: "Dọn dẹp bãi biển Vũng Tàu",
    status: "Sắp diễn ra",
    description:
        "Chiến dịch thu gom rác thải tại bãi biển Vũng Tàu, bảo vệ môi trường biển",
    location: "Bãi biển Vũng Tàu",
    dateRange: "15/4/2024 - 15/4/2024",
    currentParticipants: 45,
    maxParticipants: 100,
    currentBudget: 10000000,
    totalBudget: 15000000,
    points: 100,
    organizer: "Sở Tài nguyên Môi trường",
  ),
  Campaign(
    id: "2",
    title: "Thu gom rác tại công viên Tao Đàn",
    status: "Đã hoàn thành",
    description:
        "Hoạt động dọn dẹp và tuyên truyền bảo vệ môi trường tại công viên Tao Đàn",
    location: "Công viên Tao Đàn, TP.HCM",
    dateRange: "10/4/2024 - 12/4/2024",
    currentParticipants: 120,
    maxParticipants: 120,
    currentBudget: 8000000,
    totalBudget: 8000000,
    points: 75,
    organizer: "Đoàn Thanh niên TP.HCM",
  ),
  Campaign(
    id: "3",
    title: "Làm sạch sông Sài Gòn",
    status: "Đang diễn ra",
    description:
        "Chiến dịch lớn thu gom rác thải và làm sạch dòng sông Sài Gòn",
    location: "Sông Sài Gòn",
    dateRange: "15/4/2024 - 20/4/2024",
    currentParticipants: 25,
    maxParticipants: 200,
    currentBudget: 20000000,
    totalBudget: 45000000,
    points: 150,
    organizer: "Ủy ban Nhân dân TP.HCM",
  ),
];

// 3. MAIN APP & UI

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EcoTrack System',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFEEEEEE),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String searchText = "";

  @override
  Widget build(BuildContext context) {
    final filteredCampaigns = campaignsData.where((c) {
      return c.title.toLowerCase().contains(searchText.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Truyền dữ liệu user vào TopBar
          _buildTopBar(currentUser),

          const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),

          Expanded(
            child: Row(
              children: [
                // Sidebar
                Container(
                  width: 250,
                  color: const Color(0xFFF9F9F9),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      _buildSidebarItem(
                        Icons.people_outline,
                        "Quản lý người dùng",
                        false,
                      ),
                      _buildSidebarItem(
                        Icons.radio_button_checked,
                        "Quản lý chiến dịch",
                        true,
                      ),
                      _buildSidebarItem(
                        Icons.location_on_outlined,
                        "Bản đồ báo cáo rác",
                        false,
                      ),
                      _buildSidebarItem(
                        Icons.bar_chart,
                        "Phân tích hệ thống",
                        false,
                      ),
                    ],
                  ),
                ),

                // Main Content
                Expanded(
                  child: Container(
                    color: const Color(0xFFEEEEEE),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Text
                          const Center(
                            child: Column(
                              children: [
                                Text(
                                  "EcoTrack System",
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Hệ thống quản lý môi trường và thu gom rác thải",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Title Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Quản lý Chiến Dịch",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Tạo, chỉnh sửa và theo dõi các chiến dịch dọn dẹp môi trường",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  // Logic thêm mới
                                },
                                icon: const Icon(
                                  Icons.add,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "Tạo chiến dịch mới",
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2ECC71),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Dynamic Stats Row
                          Row(
                            children: statsData
                                .map(
                                  (stat) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                      ),
                                      child: StatCard(data: stat),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 30),

                          // List Container
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                TextField(
                                  decoration: InputDecoration(
                                    hintText:
                                        "Tìm kiếm chiến dịch theo tên hoặc địa điểm....",
                                    prefixIcon: const Icon(Icons.search),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      searchText = value;
                                    });
                                  },
                                ),

                                const SizedBox(height: 24),

                                // DYNAMIC CAMPAIGN LIST
                                // Render danh sách chiến dịch từ mảng campaignsData
                                Column(
                                  children: filteredCampaigns.map((campaign) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 20.0,
                                      ),
                                      child: CampaignCard(data: campaign),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildTopBar(UserProfile user) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: Colors.white,
      child: Row(
        children: [
          const Text(
            "EcoTrack",
            style: TextStyle(
              color: Color(0xFF009688),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Container(
            width: 400,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: const Row(
              children: [
                Icon(Icons.search, color: Colors.grey, size: 20),
                SizedBox(width: 10),
                Text(
                  "Tìm kiếm báo cáo, chiến dịch...",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_none,
                    size: 26,
                    color: Colors.grey,
                  ),
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        user.notificationCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    user.email,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.teal,
                backgroundImage: NetworkImage(user.avatarUrl),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String label, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: isActive
          ? BoxDecoration(
              color: const Color(0xFF80CBC4).withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: ListTile(
        leading: Icon(icon, color: Colors.black87, size: 20),
        title: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        dense: true,
        onTap: () {},
      ),
    );
  }
}

// Widget StatCard nhận data object
class StatCard extends StatelessWidget {
  final DashboardStat data;

  const StatCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(data.icon, color: data.color, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  data.value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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

// Widget CampaignCard nhận data object
class CampaignCard extends StatelessWidget {
  final Campaign data;

  const CampaignCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                data.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: data.statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  data.status,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
              const Spacer(),
              _actionButton(
                Icons.edit_outlined,
                () => print("Edit ${data.id}"),
              ),
              const SizedBox(width: 8),
              _actionButton(
                Icons.delete_outline,
                () => print("Delete ${data.id}"),
                isDelete: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data.description,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                data.location,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                data.dateRange,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _infoBox(
                  icon: Icons.people,
                  iconColor: Colors.blue,
                  label: "Người tham gia",
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${data.currentParticipants}/${data.maxParticipants}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: (data.currentParticipants / data.maxParticipants)
                            .clamp(0.0, 1.0), // Tính toán %
                        backgroundColor: Colors.grey[300],
                        color: Colors.blue,
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoBox(
                  icon: Icons.attach_money,
                  iconColor: Colors.green,
                  label: "Kinh phí",
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.formattedBudget,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: (data.currentBudget / data.totalBudget).clamp(
                          0.0,
                          1.0,
                        ),
                        backgroundColor: Colors.grey[300],
                        color: Colors.green,
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoBox(
                  icon: Icons.stars,
                  iconColor: Colors.orange,
                  label: "Điểm thưởng",
                  content: Text(
                    "${data.points} điểm",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoBox(
                  icon: Icons.business,
                  iconColor: Colors.purple,
                  label: "Tổ chức",
                  content: Text(
                    data.organizer,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    IconData icon,
    VoidCallback onTap, {
    bool isDelete = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDelete ? Colors.red : Colors.black54,
        ),
      ),
    );
  }

  Widget _infoBox({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Widget content,
  }) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }
}
