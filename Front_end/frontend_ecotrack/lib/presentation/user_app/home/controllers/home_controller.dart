// Home Controller
import 'campaign_controller.dart';
import 'ranking_controller.dart';
import 'recent_activity_controller.dart';
import 'welcome_card_controller.dart';
import 'profile_controller.dart';

class HomeController {
  final CampaignController campaignController = CampaignController();
  final RankingController rankingController = RankingController();
  final RecentActivityController recentActivityController =
      RecentActivityController();
  final WelcomeCardController welcomeCardController = WelcomeCardController();
  final ProfileController profileController = ProfileController();
}
