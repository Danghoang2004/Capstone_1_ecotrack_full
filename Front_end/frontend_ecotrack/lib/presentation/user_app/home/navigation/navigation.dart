// Navigation - điều hướng
class AppRoutes {
  // Campaign detail (với ID bài chiến dịch)
  static String campaignDetail(String id) => '/campaign_detail/$id';

  // Ranking detail (với ID user)
  static String rankingDetail(String id) => '/ranking_detail/$id';
}
