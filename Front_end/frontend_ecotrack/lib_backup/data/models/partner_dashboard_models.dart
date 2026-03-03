// lib/data/models/partner_dashboard_models.dart

class PartnerSponsorshipDashboard {
  final double totalRevenue;
  final int activeCoupons;
  final int couponUsage;
  final double avgRoi;
  final List<PartnerCampaignSummary> campaigns;

  PartnerSponsorshipDashboard({
    required this.totalRevenue,
    required this.activeCoupons,
    required this.couponUsage,
    required this.avgRoi,
    required this.campaigns,
  });

  factory PartnerSponsorshipDashboard.fromJson(Map<String, dynamic> json) {
    return PartnerSponsorshipDashboard(
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      activeCoupons: (json['activeCoupons'] as num?)?.toInt() ?? 0,
      couponUsage: (json['couponUsage'] as num?)?.toInt() ?? 0,
      avgRoi: (json['avgRoi'] as num?)?.toDouble() ?? 0.0,
      campaigns: (json['campaigns'] as List<dynamic>? ?? [])
          .map((e) => PartnerCampaignSummary.fromJson(e))
          .toList(),
    );
  }
}

class PartnerCampaignSummary {
  final int campaignId;
  String title;
  int participants;
  double sponsorshipAmount;
  double roiPercent;
  String statusDisplay;

  PartnerCampaignSummary({
    required this.campaignId,
    required this.title,
    required this.participants,
    required this.sponsorshipAmount,
    required this.roiPercent,
    required this.statusDisplay,
  });

  factory PartnerCampaignSummary.fromJson(Map<String, dynamic> json) {
    return PartnerCampaignSummary(
      campaignId: json['campaignId'] as int,
      title: json['title'] ?? '',
      participants: json['participants'] ?? 0,
      sponsorshipAmount: (json['sponsorshipAmount'] ?? 0).toDouble(),
      roiPercent: (json['roiPercent'] ?? 0).toDouble(),
      statusDisplay: json['statusDisplay'] ?? 'đang diễn ra',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'campaignId': campaignId,
      'title': title,
      'participants': participants,
      'sponsorshipAmount': sponsorshipAmount,
      'roiPercent': roiPercent,
      'statusDisplay': statusDisplay,
    };
  }
}
