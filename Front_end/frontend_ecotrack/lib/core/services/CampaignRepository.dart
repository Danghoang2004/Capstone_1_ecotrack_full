import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/data/models/CampaignModel.dart';

class CampaignRepository {
  final ApiClient api;

  CampaignRepository(this.api);

  Future<List<CampaignModel>> fetchActiveCampaigns() async {
    final res = await api.get('/api/campaigns/active');
    final data = api.decodeUtf8Json(res);

    return (data as List).map((e) => CampaignModel.fromJson(e, api)).toList();
  }

  Future<List<CampaignModel>> fetchUpcomingCampaigns() async {
    final res = await api.get('/api/campaigns/upcoming');
    final data = api.decodeUtf8Json(res);

    return (data as List).map((e) => CampaignModel.fromJson(e, api)).toList();
  }
}
