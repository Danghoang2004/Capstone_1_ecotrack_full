import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/CampaignRepository.dart';
import 'package:frontend_ecotrack/data/models/CampaignModel.dart';

class CampaignTakesPlaceController extends ChangeNotifier {
  final CampaignRepository repo;

  static final Set<int> _joinedCampaignIds = <int>{};
  static final Map<int, int> _participantOverrides = <int, int>{};

  CampaignTakesPlaceController(this.repo);

  List<CampaignModel> activeCampaigns = [];
  List<CampaignModel> upcomingCampaigns = [];

  bool loading = false;

  Future<void> loadData() async {
    loading = true;
    notifyListeners();

    activeCampaigns = await repo.fetchActiveCampaigns();
    upcomingCampaigns = await repo.fetchUpcomingCampaigns();

    activeCampaigns = activeCampaigns.map(_applyLocalState).toList();
    upcomingCampaigns = upcomingCampaigns.map(_applyLocalState).toList();

    loading = false;
    notifyListeners();
  }

  CampaignModel _applyLocalState(CampaignModel c) {
    final overrideCount = _participantOverrides[c.id];
    final mergedParticipants = overrideCount != null && overrideCount > c.participants
        ? overrideCount
        : c.participants;
    final mergedJoined = c.joined || _joinedCampaignIds.contains(c.id);
    return c.copyWith(participants: mergedParticipants, joined: mergedJoined);
  }

  void markCampaignJoined(int campaignId, {int? participants}) {
    _joinedCampaignIds.add(campaignId);
    if (participants != null) {
      final prev = _participantOverrides[campaignId];
      _participantOverrides[campaignId] =
          prev == null ? participants : (participants > prev ? participants : prev);
    }

    CampaignModel patch(CampaignModel c) {
      if (c.id != campaignId) return c;
      final targetParticipants = participants != null && participants > c.participants
          ? participants
          : c.participants;
      return c.copyWith(joined: true, participants: targetParticipants);
    }

    activeCampaigns = activeCampaigns.map(patch).toList();
    upcomingCampaigns = upcomingCampaigns.map(patch).toList();
    notifyListeners();
  }
}
