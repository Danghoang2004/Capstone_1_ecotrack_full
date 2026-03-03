class MonthlyActivity {
  final String month;
  final int users;
  final int reports;
  final int campaigns;

  MonthlyActivity({
    required this.month,
    required this.users,
    required this.reports,
    required this.campaigns,
  });

  factory MonthlyActivity.fromJson(Map<String, dynamic> json) {
    // Lấy nhãn tháng: ưu tiên monthLabel, fallback sang month, cuối cùng ""
    final rawMonth = (json['monthLabel'] ?? json['month'] ?? '') as String;

    final rawUsers = json['activeUsers'] ?? json['users'] ?? 0;
    final rawReports = json['wasteReports'] ?? json['reports'] ?? 0;
    final rawCampaigns = json['campaigns'] ?? 0;

    return MonthlyActivity(
      month: rawMonth,
      users: (rawUsers is num) ? rawUsers.toInt() : 0,
      reports: (rawReports is num) ? rawReports.toInt() : 0,
      campaigns: (rawCampaigns is num) ? rawCampaigns.toInt() : 0,
    );
  }
}

// ===================== DASHBOARD SUMMARY MODEL =====================
class DashboardSummary {
  final int totalUsers;
  final int totalReports;
  final int totalCampaigns;
  final int totalPoints;
  final List<MonthlyActivity> monthlyActivity;
  final Map<String, int> reportStatus;

  final double userGrowthPercent;
  final double reportGrowthPercent;
  final double campaignGrowthPercent;
  final double pointGrowthPercent;

  DashboardSummary({
    required this.totalUsers,
    required this.totalReports,
    required this.totalCampaigns,
    required this.totalPoints,
    required this.monthlyActivity,
    required this.reportStatus,
    required this.userGrowthPercent,
    required this.reportGrowthPercent,
    required this.campaignGrowthPercent,
    required this.pointGrowthPercent,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    // ----- list monthlyActivity -----
    final rawMonthly = (json['monthlyActivity'] as List?) ?? [];
    final monthly = rawMonthly
        .map((e) => MonthlyActivity.fromJson(e as Map<String, dynamic>))
        .toList();

    // ----- map reportStatus -----
    final Map<String, int> status = {};
    final rawStatus =
        (json['reportStatus'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    rawStatus.forEach((key, value) {
      if (value is num) {
        status[key] = value.toInt();
      }
    });

    num _num(dynamic v) => (v is num) ? v : 0;

    return DashboardSummary(
      totalUsers: _num(json['totalUsers']).toInt(),
      totalReports: _num(json['totalReports']).toInt(),
      totalCampaigns: _num(json['totalCampaigns']).toInt(),
      totalPoints: _num(json['totalPoints']).toInt(),
      monthlyActivity: monthly,
      reportStatus: status,
      userGrowthPercent: _num(
        json['userGrowthPercent'],
      ).toDouble(), // BE có thể trả null
      reportGrowthPercent: _num(json['reportGrowthPercent']).toDouble(),
      campaignGrowthPercent: _num(json['campaignGrowthPercent']).toDouble(),
      pointGrowthPercent: _num(json['pointGrowthPercent']).toDouble(),
    );
  }
}
