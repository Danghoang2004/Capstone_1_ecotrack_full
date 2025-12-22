class DashboardStats {
  final int activeCampaigns;
  final int upcomingCampaigns;
  final int totalParticipants;
  final double totalBudget;

  DashboardStats({
    required this.activeCampaigns,
    required this.upcomingCampaigns,
    required this.totalParticipants,
    required this.totalBudget,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      activeCampaigns: json['activeCampaigns'] ?? 0,
      upcomingCampaigns: json['upcomingCampaigns'] ?? 0,
      totalParticipants: json['totalParticipants'] ?? 0,
      totalBudget: (json['totalBudget'] ?? 0).toDouble(),
    );
  }
}
