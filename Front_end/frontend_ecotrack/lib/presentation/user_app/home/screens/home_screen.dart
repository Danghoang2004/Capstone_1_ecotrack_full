import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/header/header.dart';
import '../widgets/welcome/welcome_card.dart';
import '../widgets/actions/mini_game.dart';
import '../widgets/actions/reward.dart';
import '../widgets/ranking/ranking_section.dart';
import '../widgets/recent_activity/recent_activity_section.dart';
import '../widgets/campaign_takes_place/campaign_takes_place_section.dart';
import '../../../common/widgets/flexible_layout.dart';
import '../../campaign/checkin_screen.dart';
import '../controllers/home_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController homeController;

  @override
  void initState() {
    super.initState();
    homeController = HomeController();
    // WelcomeCard, HeaderWidget và RecentActivitySection sẽ tự load trong initState của chúng
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header (Fixed - luôn hiển thị)
            HeaderWidget(controller: homeController.profileController),

            // Scrollable content (Welcome Card, Actions, Campaign, Ranking)
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  overscroll: false,
                  physics: const ClampingScrollPhysics(),
                ),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      // Welcome Card
                      WelcomeCard(
                        controller: homeController.welcomeCardController,
                      ),

                      // Quick Actions (Báo cáo rác & Check-in)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: FlexibleLayout(
                          direction: 'row',
                          spacing: 7,
                          children: [
                            // Báo cáo rác
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.pushNamed(context, '/report');
                                },
                                child: Container(
                                  height: 110,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.green.shade100,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.camera_alt_outlined,
                                        color: Colors.green,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 7),
                                      Text(
                                        'Báo cáo rác\nChụp ảnh & GPS',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Check-in QR
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const CheckIn_screen(),
                                    ),
                                  );
                                },
                                child: Container(
                                  height: 110,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.green.shade100,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.qr_code_scanner,
                                        color: Colors.green,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 7),
                                      Text(
                                        'Check-in\nQuét QR chiến dịch',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Campaign Takes Place Section
                      CampaignTakesPlaceSection(
                        controller: homeController.campaignTakesPlaceController,
                      ),

                      const SizedBox(height: 24),

                      // Ranking Section
                      RankingSection(
                        controller: homeController.rankingController,
                      ),

                      const SizedBox(height: 24),

                      // Mini Game & Reward Actions
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: FlexibleLayout(
                          direction: 'row',
                          spacing: 12,
                          children: const [MiniGameCard(), RewardCard()],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Recent Activity Section
                      RecentActivitySection(
                        controller: homeController.recentActivityController,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
