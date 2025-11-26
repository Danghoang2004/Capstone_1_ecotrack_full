// Home Controller
import 'ranking_controller.dart';
import 'recent_activity_controller.dart';
import 'welcome_card_controller.dart';
import 'profile_controller.dart';
import 'campaign_takes_place_controller.dart';

class HomeController {
  final RankingController rankingController = RankingController();
  final RecentActivityController recentActivityController =
      RecentActivityController();
  final WelcomeCardController welcomeCardController = WelcomeCardController();
  final ProfileController profileController = ProfileController();
  final CampaignTakesPlaceController campaignTakesPlaceController =
      CampaignTakesPlaceController();
}
