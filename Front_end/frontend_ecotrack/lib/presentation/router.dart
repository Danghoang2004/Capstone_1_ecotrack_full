import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/presentation/admin_partner_web/auth_admin/AdminLoginScreen.dart';
import 'package:frontend_ecotrack/presentation/auth_user/auth_combined_screen.dart';
import 'package:frontend_ecotrack/presentation/auth_user/otp_screen.dart';
import 'package:frontend_ecotrack/presentation/user_app/CampaignList/CampaignListScreen.dart';
import 'package:frontend_ecotrack/presentation/user_app/campaign/checkin_screen.dart';
import 'package:frontend_ecotrack/presentation/user_app/home/screens/home_screen.dart';
import 'package:frontend_ecotrack/presentation/user_app/Report/Report_page.dart';
import 'package:frontend_ecotrack/presentation/user_app/minigame/quiz_overview_screen.dart';
import 'package:frontend_ecotrack/presentation/user_app/profile/ProfileScreen.dart';
import 'package:frontend_ecotrack/presentation/user_app/profile/edit_profile_screen.dart';
import 'package:frontend_ecotrack/presentation/user_app/switch_tabs/UserLayout.dart';
import 'package:frontend_ecotrack/presentation/user_app/ranking/screens/ranking_screen.dart';
import 'package:frontend_ecotrack/presentation/partner_web/auth_partner/PartnerLoginScreen.dart';
import 'package:frontend_ecotrack/presentation/partner_web/dashboard_partner/PartnerDashboardScreen.dart';
import 'package:frontend_ecotrack/presentation/user_app/voucher/rewards_screen.dart';
import '../data/models/ProfileView.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => const AuthCombinedScreen(initialIsLogin: true),
        );
      case '/login':
        return MaterialPageRoute(
          builder: (_) => const AuthCombinedScreen(initialIsLogin: true),
        );
      case '/register':
        return MaterialPageRoute(
          builder: (_) => const AuthCombinedScreen(initialIsLogin: false),
        );
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/report':
        return MaterialPageRoute(builder: (_) => const Report_page());
      case '/profile':
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(hideAppBar: false),
        );
      case '/user_app':
        final showWelcomeDialog = settings.arguments as bool? ?? false;
        return MaterialPageRoute(
          builder: (_) => Userlayout(showWelcomeDialog: showWelcomeDialog),
        );
      case '/otp':
        final email = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => OtpScreenSingle(email: email));
      case '/QR_check':
        return MaterialPageRoute(builder: (context) => CheckIn_screenreal());
      case '/ranking':
        // Mobile: Giữ nguyên
        return MaterialPageRoute(builder: (_) => const RankingScreen());
      case '/partner_login':
        return MaterialPageRoute(builder: (_) => const PartnerLoginScreen());
      case '/admin_login':
        return MaterialPageRoute(builder: (_) => const AdminLoginScreen());
      case '/campaigns':
        return MaterialPageRoute(builder: (_) => const CampaignListScreen());
      case '/partner_dashboard':
        return MaterialPageRoute(
          builder: (_) => const PartnerDashboardScreen(),
        );
      case '/minigame':
        // chỉ cần userId, quizId sẽ chọn ở màn overview
        final args = settings.arguments as Map<String, dynamic>?;

        final int userId =
            (args?['userId'] as int?) ?? 0; // hoặc current user id

        return MaterialPageRoute(
          builder: (context) => QuizOverviewScreen(userId: userId),
        );
      case '/voucher':
        return MaterialPageRoute(builder: (_) => const RewardsScreen());
      case '/editprofile':
        // 1. Lấy dữ liệu từ arguments và ép kiểu về ProfileView
        final profile = settings.arguments as ProfileView;

        // 2. Bỏ từ khóa 'const' vì profile là biến động
        return MaterialPageRoute(
          builder: (_) => EditProfileScreen(currentProfile: profile),
        );
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text("Page not found"))),
        );
    }
  }
}
