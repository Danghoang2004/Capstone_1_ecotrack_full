import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/CampaignRepository.dart';
import 'package:frontend_ecotrack/data/models/CampaignModel.dart';

class CampaignTakesPlaceController extends ChangeNotifier {
  final CampaignRepository repo;

  CampaignTakesPlaceController(this.repo);

  List<CampaignModel> activeCampaigns = [];
  List<CampaignModel> upcomingCampaigns = [];

  bool loading = false;

  Future<void> loadData() async {
    loading = true;
    notifyListeners();

    activeCampaigns = await repo.fetchActiveCampaigns();
    upcomingCampaigns = await repo.fetchUpcomingCampaigns();

    loading = false;
    notifyListeners();
  }
}
