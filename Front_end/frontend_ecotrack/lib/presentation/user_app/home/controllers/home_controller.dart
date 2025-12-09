import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/CampaignRepository.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/presentation/user_app/home/controllers/campaign_takes_place_controller.dart';

import 'ranking_controller.dart';
import 'recent_activity_controller.dart';
import 'welcome_card_controller.dart';
import 'profile_controller.dart';

class HomeController {
  final RankingController rankingController = RankingController();
  final RecentActivityController recentActivityController =
      RecentActivityController();
  final WelcomeCardController welcomeCardController = WelcomeCardController();
  final ProfileController profileController = ProfileController();
  final CampaignTakesPlaceController campaignTakesPlaceController =
      CampaignTakesPlaceController(
        CampaignRepository(ApiClient(storage: const FlutterSecureStorage())),
      );
}
