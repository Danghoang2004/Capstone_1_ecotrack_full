import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend_ecotrack/core/services/auth_service.dart';
import 'package:frontend_ecotrack/core/services/admin_dashboard_api.dart';
import 'package:frontend_ecotrack/data/models/dashboard_models.dart';

const Color primaryGreen = Color(0xFF00B894);
const Color sidebarBg = Colors.white;
const Color pageBg = Color(0xFFF7F8FA);
const Color cardBg = Colors.white;

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AuthService _authService = AuthService();
  final AdminDashboardApi _api = AdminDashboardApi();

  late Future<DashboardSummary> _futureDashboard;
  String _username = "";
  String _email = "";

  @override
  void initState() {
    super.initState();
    _futureDashboard = _api.fetchDashboard();
    _loadAdminInfo();
  }

  Future<void> _loadAdminInfo() async {
    final name = await _authService.getUsername();
    final mail = await _authService.getEmail();

    if (!mounted) return;

    setState(() {
      _username = name ?? "Admin";
      _email = mail ?? "";
    });
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/admin_login',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      body: Column(
        children: [
          // ===== HEADER FULL WIDTH =====
          _buildTopBar(),

          // ===== PHẦN DƯỚI: SIDEBAR + NỘI DUNG =====
          Expanded(
            child: FutureBuilder<DashboardSummary>(
              future: _futureDashboard,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text("Lỗi tải dữ liệu: ${snap.error}"));
                }

                final data = snap.data!;

                return Row(
                  children: [
                    // Sidebar bên trái
                    _buildSidebar(),

                    // Nội dung dashboard bên phải
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                        child: _buildDashboardContent(data),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===================== TOP BAR =====================
  Widget _buildTopBar() {
    return Container(
      height: 80,
      padding: const EdgeInsets.fromLTRB(50, 16, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text(
            "EcoTrack",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: primaryGreen,
            ),
          ),
          const SizedBox(width: 40),
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, size: 20),
                  hintText: "Tìm kiếm báo cáo, chiến dịch...",
                  hintStyle: const TextStyle(fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFFF4F5F7),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 40),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined),
                onPressed: () {},
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    "2",
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _username.isNotEmpty ? _username : "Admin",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (_email.isNotEmpty)
                    Text(
                      _email,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFFFE0B2),
                child: Icon(Icons.person, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===================== SIDEBAR =====================
  Widget _buildSidebar() {
    return Container(
      width: 270,
      color: sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SizedBox(height: 15),
          _SidebarItem(
            icon: Icons.people_outline,
            label: "Quản Lý Người Dùng",
            selected: false,
            onTap: null,
          ),
          _SidebarItem(
            icon: Icons.campaign_outlined,
            label: "Quản Lý Chiến Dịch",
            selected: false,
            onTap: null,
          ),
          _SidebarItem(
            icon: Icons.map_outlined,
            label: "Bản Đồ Báo Cáo Rác",
            selected: false,
            onTap: null,
          ),
          _SidebarItem(
            icon: Icons.bar_chart,
            label: "Phân Tích Hệ Thống",
            selected: true,
            onTap: null,
          ),
        ],
      ),
    );
  }

  // ===================== MAIN CONTENT =====================
  Widget _buildDashboardContent(DashboardSummary data) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Phân Tích Hệ Thống",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 1),
          const Text(
            "Thống kê và báo cáo tổng quan về hoạt động hệ thống EcoTrack",
            style: TextStyle(color: Colors.grey, fontSize: 10),
          ),
          const SizedBox(height: 18),

          // ===== TOP STATS CARDS =====
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 270,
                height: 177,
                child: _StatCard(
                  title: "Tổng người dùng",
                  value: data.totalUsers.toString(),
                  subtitle:
                      "${data.userGrowthPercent.toStringAsFixed(1)}% so với tháng trước",
                  icon: Icons.group_outlined,
                  iconBg: const Color(0xFFE8F4FF),
                  valueColor: Colors.black,
                  subtitleColor: const Color(0xFF00B894),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 270,
                height: 177,
                child: _StatCard(
                  title: "Báo cáo rác",
                  value: data.totalReports.toString(),
                  subtitle:
                      "${data.reportGrowthPercent.toStringAsFixed(1)}% so với tháng trước",
                  icon: Icons.place_outlined,
                  iconBg: const Color(0xFFFFEBEE),
                  valueColor: Colors.black,
                  subtitleColor: const Color(0xFF00B894),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 270,
                height: 177,
                child: _StatCard(
                  title: "Chiến dịch",
                  value: data.totalCampaigns.toString(),
                  subtitle:
                      "${data.campaignGrowthPercent.toStringAsFixed(1)}% so với tháng trước",
                  icon: Icons.radio_button_checked_outlined,
                  iconBg: const Color(0xFFE8F8F2),
                  valueColor: Colors.black,
                  subtitleColor: const Color(0xFF00B894),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 270,
                height: 177,
                child: _StatCard(
                  title: "Điểm thưởng",
                  value: data.totalPoints.toString(),
                  subtitle:
                      "${data.pointGrowthPercent.toStringAsFixed(1)}% so với tháng trước",
                  icon: Icons.emoji_events_outlined,
                  iconBg: const Color(0xFFFFF8E1),
                  valueColor: Colors.black,
                  subtitleColor: const Color(0xFF00B894),
                ),
              ),
            ],
          ),

          const SizedBox(height: 26),

          // ===== LINE + PIE CHART =====
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildLineChartCard(data)),
              const SizedBox(width: 20),
              Expanded(child: _buildPieChart(data)),
            ],
          ),

          const SizedBox(height: 26),

          // ===== THAM GIA CHIẾN DỊCH + PHÂN BỐ CẤP ĐỘ =====
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildCampaignParticipationCard()),
              const SizedBox(width: 20),
              Expanded(child: _buildUserLevelDistributionCard()),
            ],
          ),

          const SizedBox(height: 26),

          // ===== HOẠT ĐỘNG GẦN ĐÂY =====
          _buildRecentActivityCard(),
        ],
      ),
    );
  }

  // ===================== LINE CHART CARD =====================
  Widget _buildLineChartCard(DashboardSummary data) {
    // ====== TÍNH DỮ LIỆU NHƯ CŨ ======
    final usersSpots = <FlSpot>[];
    final reportsSpots = <FlSpot>[];
    final campaignsSpots = <FlSpot>[];

    double maxY = 0;

    for (int i = 0; i < data.monthlyActivity.length; i++) {
      final m = data.monthlyActivity[i];

      final u = m.users.toDouble();
      final r = m.reports.toDouble();
      final c = m.campaigns.toDouble();

      usersSpots.add(FlSpot(i.toDouble(), u));
      reportsSpots.add(FlSpot(i.toDouble(), r));
      campaignsSpots.add(FlSpot(i.toDouble(), c));

      maxY = [maxY, u, r, c].reduce((a, b) => a > b ? a : b);
    }

    if (maxY < 10) maxY = 10;
    maxY = ((maxY / 20).ceil() * 20).toDouble();

    // ====== CARD + CHART ĐÃ SỬA ======
    return _CardContainer(
      title: "Xu hướng hoạt động theo tháng",
      // chiều cao cố định, không cho “co giãn” khi tooltip xuất hiện
      height: 360,
      child: SizedBox.expand(
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (data.monthlyActivity.length - 1).toDouble(),
            minY: 0,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 4,
            ),
            borderData: FlBorderData(
              show: true,
              border: const Border(
                left: BorderSide(color: Colors.black45, width: 1),
                bottom: BorderSide(color: Colors.black45, width: 1),
                right: BorderSide(color: Colors.transparent),
                top: BorderSide(color: Colors.transparent),
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: maxY / 4,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= data.monthlyActivity.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        data.monthlyActivity[idx].month, // "T1".."T5"
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),

            // ===== TOOLTIP KHÔNG LÀM LỆCH LAYOUT =====
            lineTouchData: LineTouchData(
              enabled: false,
              handleBuiltInTouches: true,
              touchTooltipData: LineTouchTooltipData(
                tooltipRoundedRadius: 8,
                tooltipPadding: const EdgeInsets.all(8),
                tooltipMargin: 8,
                tooltipBorder: const BorderSide(color: Colors.black12),
                getTooltipColor: (spot) => Colors.white,
                // ép tooltip nằm GỌN trong chart, không đẩy layout ra ngoài
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipItems: (touchedSpots) {
                  if (touchedSpots.isEmpty) return [];

                  final idx = touchedSpots.first.x.toInt();
                  final m = data.monthlyActivity[idx];

                  return [
                    LineTooltipItem(
                      '${m.month}\n',
                      const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black,
                      ),
                    ),
                    LineTooltipItem(
                      'Báo cáo: ${m.reports}\n',
                      const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                    LineTooltipItem(
                      'Chiến dịch: ${m.campaigns}\n',
                      const TextStyle(color: Colors.green, fontSize: 12),
                    ),
                    LineTooltipItem(
                      'Người dùng: ${m.users}',
                      const TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ];
                },
              ),
            ),

            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                color: const Color(0xFF2962FF),
                barWidth: 2.5,
                spots: usersSpots,
                dotData: FlDotData(show: false),
              ),
              LineChartBarData(
                isCurved: true,
                color: const Color(0xFFFF5252),
                barWidth: 2.5,
                spots: reportsSpots,
                dotData: FlDotData(show: false),
              ),
              LineChartBarData(
                isCurved: true,
                color: const Color(0xFF00C853),
                barWidth: 2.5,
                spots: campaignsSpots,
                dotData: FlDotData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== PIE CHART CARD =====================
  Widget _buildPieChart(DashboardSummary data) {
    final total = data.reportStatus.values.fold<int>(0, (p, e) => p + e);

    final orderedKeys = ["PENDING", "VERIFIED", "CLEANED", "REJECTED"];

    final viLabel = {
      "PENDING": "Đang chờ xử lý",
      "VERIFIED": "Đã xác minh",
      "CLEANED": "Đã dọn dẹp",
      "REJECTED": "Bị từ chối",
    };

    final colors = {
      "PENDING": const Color(0xFFB39DDB),
      "VERIFIED": const Color(0xFF9575CD),
      "CLEANED": const Color(0xFF7E57C2),
      "REJECTED": const Color(0xFF673AB7),
    };

    return _CardContainer(
      title: "Trạng thái báo cáo rác",
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 0,
                sections: orderedKeys.map((key) {
                  final value = data.reportStatus[key] ?? 0;
                  if (total == 0 || value == 0) {
                    return PieChartSectionData(value: 0, title: "");
                  }
                  final percent = (value / total) * 100;
                  return PieChartSectionData(
                    value: value.toDouble(),
                    title: "${percent.toStringAsFixed(0)}%",
                    radius: 60,
                    color: colors[key],
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: orderedKeys.map((key) {
                final value = data.reportStatus[key] ?? 0;
                final percent = total == 0 ? 0 : (value / total * 100).round();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colors[key],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${viLabel[key]} $percent%",
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== THAM GIA CHIẾN DỊCH =====================
  Widget _buildCampaignParticipationCard() {
    final participants = [80.0, 60.0, 90.0, 120.0];
    final spots = <FlSpot>[];

    for (int i = 0; i < participants.length; i++) {
      spots.add(FlSpot((i + 1).toDouble(), participants[i]));
    }

    final maxValue = participants.reduce((a, b) => a > b ? a : b);
    final maxY = ((maxValue / 20).ceil() * 20).toDouble();

    return _CardContainer(
      title: "Tham gia chiến dịch",
      height: 320,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: maxY / 4,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 11),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 1 || idx > participants.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      idx.toString(),
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: const Border(
              left: BorderSide(color: Colors.black45, width: 1),
              bottom: BorderSide(color: Colors.black45, width: 1),
              right: BorderSide(color: Colors.transparent),
              top: BorderSide(color: Colors.transparent),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              color: const Color(0xFF2962FF),
              barWidth: 2.5,
              spots: spots,
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== PHÂN BỐ CẤP ĐỘ NGƯỜI DÙNG =====================
  Widget _buildUserLevelDistributionCard() {
    final levels = [
      _LevelData("Bronze", const Color(0xFF8D6E63), 180),
      _LevelData("Silver", const Color(0xFFB0BEC5), 95),
      _LevelData("Gold", const Color(0xFFFFD54F), 45),
      _LevelData("Platinum", const Color(0xFFE0E0E0), 12),
    ];

    final maxCount = levels.map((e) => e.count).reduce((a, b) => a > b ? a : b);

    return _CardContainer(
      title: "Phân bố cấp độ người dùng",
      height: 320,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: levels.map((level) {
          final ratio = level.count / maxCount;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: level.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 70,
                  child: Text(level.name, style: const TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: ratio,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: level.color,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 40,
                  child: Text(
                    level.count.toString(),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ===================== HOẠT ĐỘNG GẦN ĐÂY =====================
  Widget _buildRecentActivityCard() {
    final activities = [
      _ActivityItem(
        color: const Color(0xFF00C853),
        title: "Chiến dịch \"Dọn dẹp bãi biển Vũng Tàu\" đã hoàn thành",
        time: "2 giờ trước · 120 người tham gia",
      ),
      _ActivityItem(
        color: const Color(0xFF2962FF),
        title: "15 báo cáo rác mới đã được xác minh",
        time: "2 giờ trước · 120 người tham gia",
      ),
      _ActivityItem(
        color: const Color(0xFFFFAB00),
        title: "25 người dùng mới đăng ký tham gia hệ thống",
        time: "2 giờ trước · 120 người tham gia",
      ),
      _ActivityItem(
        color: const Color(0xFF00B894),
        title: "Chiến dịch \"Làm sạch sông Sài Gòn\" đã được tạo",
        time: "2 giờ trước · 120 người tham gia",
      ),
    ];

    return _CardContainer(
      title: "Hoạt động gần đây",
      height: 260,
      child: ListView.separated(
        itemCount: activities.length,
        itemBuilder: (context, index) {
          final item = activities[index];
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.time,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 8),
      ),
    );
  }
}

// ===================== REUSABLE WIDGETS & MODELS =====================

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: selected ? primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : Colors.black87,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color valueColor;
  final Color subtitleColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.valueColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      size: 14,
                      color: Color(0xFF00B894),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: subtitleColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  final String title;
  final Widget child;
  final double? height;

  const _CardContainer({required this.title, required this.child, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 360,
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _LevelData {
  final String name;
  final Color color;
  final int count;

  _LevelData(this.name, this.color, this.count);
}

class _ActivityItem {
  final Color color;
  final String title;
  final String time;

  _ActivityItem({required this.color, required this.title, required this.time});
}
