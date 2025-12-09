import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/theme/app_colors.dart';
import 'package:frontend_ecotrack/presentation/user_app/home/widgets/campaign_takes_place/CampaignTakesPlaceSection.dart';

import '../widgets/header/header.dart';
import '../widgets/welcome/welcome_card.dart';
import '../widgets/actions/mini_game.dart';
import '../widgets/actions/reward.dart';
import '../widgets/ranking/ranking_section.dart';
import '../widgets/recent_activity/recent_activity_section.dart';
import '../widgets/welcome_dialog/welcome_dialog.dart';
import '../controllers/home_controller.dart';

class HomeScreen extends StatefulWidget {
  final bool showWelcomeDialog;
  final bool hideHeader;

  const HomeScreen({
    super.key,
    this.showWelcomeDialog = false,
    this.hideHeader = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController homeController;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _hasCheckedWelcomeDialog = false;

  @override
  void initState() {
    super.initState();
    homeController = HomeController();
    homeController.rankingController.loadWeeklyRankings().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
    homeController.recentActivityController.loadActivities().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
    _checkAndShowWelcomeDialog();
  }

  Future<void> _checkAndShowWelcomeDialog() async {
    if (!widget.showWelcomeDialog) {
      return;
    }

    if (_hasCheckedWelcomeDialog) return;
    _hasCheckedWelcomeDialog = true;

    final hasShown = await _storage.read(key: 'has_shown_welcome_dialog');
    if (hasShown == 'true') {
      return;
    }

    try {
      await homeController.welcomeCardController.loadProfile();
      final profile = homeController.welcomeCardController.profile;

      if (profile != null && mounted) {
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          await WelcomeDialog.show(
            context,
            fullName: profile.fullName.isNotEmpty
                ? profile.fullName
                : (profile.username.isNotEmpty
                      ? profile.username
                      : 'Người dùng'),
            points: profile.points,
          );

          await _storage.write(key: 'has_shown_welcome_dialog', value: 'true');
        }
      }
    } catch (e) {
      // Nếu có lỗi, không hiển thị dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final maxContentWidth = isDesktop ? 1200.0 : double.infinity;
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: HomeColors.bgHeader, // MÀU HEADER
        statusBarBrightness: Brightness.light, // iOS
        statusBarIconBrightness: Brightness.dark, // Android icons đen
      ),
    );
    return Scaffold(
      backgroundColor: isDesktop
          ? Colors.white
          : const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: Column(
          children: [
            if (!widget.hideHeader)
              HeaderWidget(controller: homeController.profileController),

            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  overscroll: false,
                  physics: const ClampingScrollPhysics(),
                ),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: isDesktop
                          ? _buildDesktopLayout()
                          : _buildMobileLayout(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        WelcomeCard(controller: homeController.welcomeCardController),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
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
                      border: Border.all(color: Colors.green.shade100),
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
              const SizedBox(width: 7),
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/QR_check');
                  },
                  child: Container(
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade100),
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

        CampaignTakesPlaceSection(
          controller: homeController.campaignTakesPlaceController,
        ),

        const SizedBox(height: 24),

        RankingSection(controller: homeController.rankingController),

        const SizedBox(height: 24),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Đố Vui Và Đổi Thưởng',
                style: TextStyle(
                  fontSize: 20, // giống Bảng Xếp Hạng Tuần
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              MiniGameCard(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/minigame',
                    arguments: {
                      'userId':
                          homeController.profileController.profile?.userId ?? 0,
                    },
                  );
                },
              ),
              SizedBox(width: 12),
              RewardCard(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/voucher',
                    arguments: {
                      'userId':
                          homeController.profileController.profile?.userId ?? 0,
                    },
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        RecentActivitySection(
          controller: homeController.recentActivityController,
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cột trái (60%) - NỀN TRONG SUỐT
          Expanded(
            flex: 6,
            child: Column(
              children: [
                WelcomeCard(controller: homeController.welcomeCardController),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, '/report');
                        },
                        child: Container(
                          height: 130,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green.shade100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                color: Colors.green,
                                size: 40,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Báo cáo rác\nChụp ảnh & GPS',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, '/QR_check');
                        },
                        child: Container(
                          height: 130,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green.shade100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_scanner,
                                color: Colors.green,
                                size: 40,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Check-in\nQuét QR chiến dịch',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                CampaignTakesPlaceSection(
                  controller: homeController.campaignTakesPlaceController,
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    MiniGameCard(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/minigame',
                          arguments: {
                            'userId':
                                homeController
                                    .profileController
                                    .profile
                                    ?.userId ??
                                0,
                          },
                        );
                      },
                    ),
                    SizedBox(width: 16),
                    RewardCard(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/voucher',
                          arguments: {
                            'userId':
                                homeController
                                    .profileController
                                    .profile
                                    ?.userId ??
                                0,
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 24),

          // Cột phải (40%) - Nền trắng với shadow mạnh
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                    spreadRadius: 4,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  RankingSection(controller: homeController.rankingController),

                  const SizedBox(height: 24),

                  RecentActivitySection(
                    controller: homeController.recentActivityController,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
