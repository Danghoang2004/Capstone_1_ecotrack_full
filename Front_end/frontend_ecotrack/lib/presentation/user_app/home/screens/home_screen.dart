import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/header/header.dart';
import '../widgets/welcome/welcome_card.dart';
import '../widgets/actions/upload.dart';
import '../widgets/actions/qr_scan.dart';
import '../widgets/actions/mini_game.dart';
import '../widgets/actions/reward.dart';
import '../widgets/campaign/campaign_section.dart';
import '../widgets/ranking/ranking_section.dart';
import '../widgets/recent_activity/recent_activity_section.dart';
import '../../../common/widgets/flexible_layout.dart';
import '../controllers/home_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Tạo controller chính tổng hợp
    final homeController = HomeController();

    return Scaffold(
      backgroundColor: HomeColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header (Fixed - luôn hiển thị)
            HeaderWidget(controller: homeController.profileController),

            // Scrollable content (Welcome Card, Actions, Campaign, Ranking)
            Expanded(
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
                          UploadCard(
                            controller: homeController.uploadController,
                          ),
                          const QrScanCard(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Campaign Section
                    CampaignSection(
                      controller: homeController.campaignController,
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
          ],
        ),
      ),
    );
  }
}
