import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/theme/app_colors.dart';
import 'package:frontend_ecotrack/core/services/admin_dashboard_api.dart';
import 'package:frontend_ecotrack/data/models/dashboard_models.dart';

const Color primaryGreen = AppColors.adminAccent;
const Color sidebarBg = AppColors.adminSurface;
const Color pageBg = AppColors.adminBackground;
const Color cardBg = AppColors.adminSurface;

class AdminDashboardDataScreen extends StatefulWidget {
  const AdminDashboardDataScreen({super.key});

  @override
  State<AdminDashboardDataScreen> createState() =>
      _AdminDashboardDataScreenState();
}

class _AdminDashboardDataScreenState extends State<AdminDashboardDataScreen> {
  final AdminDashboardApi _api = AdminDashboardApi();
  late Future<DashboardSummary> _futureDashboard;

  @override
  void initState() {
    super.initState();
    _futureDashboard = _api.fetchDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardSummary>(
      future: _futureDashboard,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text("Lỗi dữ liệu: ${snap.error}"));
        }

        final data = snap.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: _buildDashboardContent(data),
            ),
          ),
        );
      },
    );
  }

  // ===================== MAIN CONTENT =====================
  Widget _buildDashboardContent(DashboardSummary data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double viewportWidth = constraints.maxWidth;
        final int statsPerRow = viewportWidth >= 980
            ? 4
          : viewportWidth >= 760
                    ? 2
                    : 1;
        final double statsGap = 16;
        final double statsCardWidth =
            (viewportWidth - (statsGap * (statsPerRow - 1))) / statsPerRow;
        final bool useTwoColumns = viewportWidth >= 980;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroBanner(data),
            const SizedBox(height: 22),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: statsCardWidth,
                  child: _StatCard(
                    title: "Tổng người dùng",
                    value: data.totalUsers.toString(),
                    subtitle:
                        "${data.userGrowthPercent.toStringAsFixed(1)}% so với tháng trước",
                    icon: Icons.group_outlined,
                    iconBg: const Color(0xFFE4F2E8),
                    cardTint: const Color(0xFFF5FBF7),
                    valueColor: AppColors.adminTextPrimary,
                    subtitleColor: AppColors.adminAccent,
                  ),
                ),
                SizedBox(
                  width: statsCardWidth,
                  child: _StatCard(
                    title: "Báo cáo rác",
                    value: data.totalReports.toString(),
                    subtitle:
                        "${data.reportGrowthPercent.toStringAsFixed(1)}% so với tháng trước",
                    icon: Icons.place_outlined,
                    iconBg: const Color(0xFFFFF0E3),
                    cardTint: const Color(0xFFFFFAF4),
                    valueColor: AppColors.adminTextPrimary,
                    subtitleColor: AppColors.adminAccent,
                  ),
                ),
                SizedBox(
                  width: statsCardWidth,
                  child: _StatCard(
                    title: "Chiến dịch",
                    value: data.totalCampaigns.toString(),
                    subtitle:
                        "${data.campaignGrowthPercent.toStringAsFixed(1)}% so với tháng trước",
                    icon: Icons.radio_button_checked_outlined,
                    iconBg: const Color(0xFFE6F4F1),
                    cardTint: const Color(0xFFF2FAF8),
                    valueColor: AppColors.adminTextPrimary,
                    subtitleColor: AppColors.adminAccent,
                  ),
                ),
                SizedBox(
                  width: statsCardWidth,
                  child: _StatCard(
                    title: "Điểm thưởng",
                    value: data.totalPoints.toString(),
                    subtitle:
                        "${data.pointGrowthPercent.toStringAsFixed(1)}% so với tháng trước",
                    icon: Icons.emoji_events_outlined,
                    iconBg: const Color(0xFFFFF5D9),
                    cardTint: const Color(0xFFFFFCEF),
                    valueColor: AppColors.adminTextPrimary,
                    subtitleColor: AppColors.adminAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            if (useTwoColumns)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: _buildLineChartCard(data)),
                  const SizedBox(width: 20),
                  Expanded(flex: 5, child: _buildPieChart(data)),
                ],
              )
            else
              Column(
                children: [
                  _buildLineChartCard(data),
                  const SizedBox(height: 20),
                  _buildPieChart(data),
                ],
              ),
            const SizedBox(height: 26),
            if (useTwoColumns)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: _buildCampaignParticipationCard()),
                  const SizedBox(width: 20),
                  Expanded(flex: 5, child: _buildUserLevelDistributionCard()),
                ],
              )
            else
              Column(
                children: [
                  _buildCampaignParticipationCard(),
                  const SizedBox(height: 20),
                  _buildUserLevelDistributionCard(),
                ],
              ),
            const SizedBox(height: 26),
            _buildRecentActivityCard(),
          ],
        );
      },
    );
  }

  Widget _buildHeroBanner(DashboardSummary data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      decoration: BoxDecoration(
        gradient: AppColors.adminHeroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.adminAccent.withOpacity(0.16),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool compact = constraints.maxWidth < 860;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildHeroChip(
                    'Tổng quan hệ thống',
                    const Color(0x365BF0AA),
                    const Color(0xFFEFFFF7),
                  ),
                  _buildHeroChip(
                    'Cập nhật theo thời gian thực',
                    const Color(0x3CFFB06A),
                    const Color(0xFFFFF5E8),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (compact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Phân Tích Hệ Thống',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Thống kê và báo cáo tổng quan về hoạt động hệ thống EcoTrack',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.86),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Phân Tích Hệ Thống',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.7,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Thống kê và báo cáo tổng quan về hoạt động hệ thống EcoTrack',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.86),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildHeroMetric('Người dùng', data.totalUsers.toString()),
                        _buildHeroMetric('Báo cáo', data.totalReports.toString()),
                        _buildHeroMetric('Chiến dịch', data.totalCampaigns.toString()),
                      ],
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroChip(String label, Color color, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildHeroMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
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
                      const TextStyle(color: Color(0xFF2F8DE4), fontSize: 12),
                    ),
                    LineTooltipItem(
                      'Người dùng: ${m.users}',
                      const TextStyle(color: Color(0xFF1FA971), fontSize: 12),
                    ),
                  ];
                },
              ),
            ),

            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                color: const Color(0xFF2F8C4C),
                barWidth: 2.5,
                spots: usersSpots,
                dotData: FlDotData(show: false),
              ),
              LineChartBarData(
                isCurved: true,
                color: AppColors.adminAccentWarm,
                barWidth: 2.5,
                spots: reportsSpots,
                dotData: FlDotData(show: false),
              ),
              LineChartBarData(
                isCurved: true,
                color: AppColors.adminAccentSky,
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
      "PENDING": const Color(0xFF90A4AE),
      "VERIFIED": const Color(0xFF2F8C4C),
      "CLEANED": AppColors.adminAccentSky,
      "REJECTED": AppColors.adminAccentWarm,
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
              color: const Color(0xFF2F8C4C),
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
      _LevelData("Silver", const Color(0xFF90A4AE), 95),
      _LevelData("Gold", AppColors.adminAccent, 45),
      _LevelData("Platinum", AppColors.adminAccentSky, 12),
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
                          color: AppColors.adminSurfaceMuted,
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
            color: AppColors.adminAccent,
        title: "Chiến dịch \"Dọn dẹp bãi biển Vũng Tàu\" đã hoàn thành",
        time: "2 giờ trước · 120 người tham gia",
      ),
      _ActivityItem(
            color: AppColors.adminAccentSky,
        title: "15 báo cáo rác mới đã được xác minh",
        time: "2 giờ trước · 120 người tham gia",
      ),
      _ActivityItem(
        color: AppColors.adminAccentWarm,
        title: "25 người dùng mới đăng ký tham gia hệ thống",
        time: "2 giờ trước · 120 người tham gia",
      ),
      _ActivityItem(
        color: const Color(0xFF28B89A),
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
  final Color? cardTint;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.valueColor,
    required this.subtitleColor,
    this.cardTint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardTint ?? cardBg,
            AppColors.adminSurface,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.adminBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
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
              borderRadius: BorderRadius.circular(14),
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
                  style: const TextStyle(
                    color: AppColors.adminTextSecondary,
                    fontSize: 13,
                  ),
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
                      color: AppColors.adminAccent,
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.adminBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.adminTextPrimary,
            ),
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
