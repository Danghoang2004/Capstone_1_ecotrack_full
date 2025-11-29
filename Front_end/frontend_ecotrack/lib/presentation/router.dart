import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/presentation/auth_user/LoginScreen.dart';
import 'package:frontend_ecotrack/presentation/auth_user/otp_screen.dart';
import 'package:frontend_ecotrack/presentation/user_app/home/screens/home_screen.dart';
import 'package:frontend_ecotrack/presentation/user_app/Report/Report_page.dart';
import 'package:frontend_ecotrack/presentation/user_app/upload_report/upload_report.dart';
import 'package:frontend_ecotrack/presentation/user_app/profile/ProfileScreen.dart';
import 'package:frontend_ecotrack/presentation/user_app/switch_tabs/UserLayout.dart';
import 'package:frontend_ecotrack/presentation/user_app/ranking/screens/ranking_screen.dart';
import 'package:frontend_ecotrack/presentation/partner_web/auth_partner/PartnerLoginScreen.dart';
import 'package:frontend_ecotrack/presentation/partner_web/dashboard_partner/PartnerDashboardScreen.dart';
import 'auth_user/register_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/report':
        return MaterialPageRoute(builder: (_) => const Report_page());
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case '/user_app':
        final showWelcomeDialog = settings.arguments as bool? ?? false;
        return MaterialPageRoute(
          builder: (_) => Userlayout(showWelcomeDialog: showWelcomeDialog),
        );
      case '/otp':
        final email = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => OtpScreenSingle(email: email));
      case '/QR_check':
        return MaterialPageRoute(builder: (context) => CheckIn_screen());
      case '/ranking':
        // Mobile: Giữ nguyên
        return MaterialPageRoute(builder: (_) => const RankingScreen());
      case '/partner_login':
        return MaterialPageRoute(builder: (_) => const PartnerLoginScreen());
      case '/partner_dashboard':
        return MaterialPageRoute(
          builder: (_) => const PartnerDashboardScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text("Page not found"))),
        );
    }
  }
}
