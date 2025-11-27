import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/header/header.dart';
import '../widgets/welcome/welcome_card.dart';
import '../widgets/actions/mini_game.dart';
import '../widgets/actions/reward.dart';
import '../widgets/ranking/ranking_section.dart';
import '../widgets/recent_activity/recent_activity_section.dart';
import '../widgets/campaign_takes_place/campaign_takes_place_section.dart';
import '../widgets/welcome_dialog/welcome_dialog.dart';
import '../../../common/widgets/flexible_layout.dart';
import '../../campaign/checkin_screen.dart';
import '../controllers/home_controller.dart';

class HomeScreen extends StatefulWidget {
  final bool showWelcomeDialog;
  final bool hideHeader;

  const HomeScreen({super.key, this.showWelcomeDialog = false, this.hideHeader = false});

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
    // WelcomeCard, HeaderWidget và RecentActivitySection sẽ tự load trong initState của chúng
    // Load ranking data
    homeController.rankingController.loadWeeklyRankings().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
    // Load recent activities data
    homeController.recentActivityController.loadActivities().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
    // Check và hiển thị welcome dialog nếu cần
    _checkAndShowWelcomeDialog();
  }

  Future<void> _checkAndShowWelcomeDialog() async {
    // Chỉ hiển thị dialog nếu được truyền flag từ OTP screen (đăng ký lần đầu)
    if (!widget.showWelcomeDialog) {
      return; // Không phải đăng ký lần đầu, không hiển thị
    }

    if (_hasCheckedWelcomeDialog) return;
    _hasCheckedWelcomeDialog = true;

    // Kiểm tra xem đã hiển thị dialog chưa (để tránh hiển thị nhiều lần nếu có lỗi)
    final hasShown = await _storage.read(key: 'has_shown_welcome_dialog');
    if (hasShown == 'true') {
      return; // Đã hiển thị rồi, không hiển thị nữa
    }

    // Load profile để lấy fullname và points
    try {
      await homeController.welcomeCardController.loadProfile();
      final profile = homeController.welcomeCardController.profile;

      if (profile != null && mounted) {
        // Đợi một chút để UI render xong
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          // Hiển thị dialog
          await WelcomeDialog.show(
            context,
            fullName: profile.fullName.isNotEmpty
                ? profile.fullName
                : (profile.username.isNotEmpty ? profile.username : 'Người dùng'),
            points: profile.points,
          );

          // Lưu flag đã hiển thị (để đảm bảo chỉ hiển thị 1 lần)
          await _storage.write(key: 'has_shown_welcome_dialog', value: 'true');
        }
      }
    } catch (e) {
      // Nếu có lỗi, không hiển thị dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header (Fixed - luôn hiển thị, trừ khi hideHeader = true)
            if (!widget.hideHeader)
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
