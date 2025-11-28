import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/presentation/auth_user/LoginScreen.dart';
import 'package:frontend_ecotrack/presentation/auth_user/otp_screen.dart';
import 'package:frontend_ecotrack/presentation/user_app/Home/Home_screen.dart';
import 'package:frontend_ecotrack/presentation/user_app/Report/Report_page.dart';
import 'package:frontend_ecotrack/presentation/user_app/campaign/checkin_screen.dart';
import 'package:frontend_ecotrack/presentation/user_app/minigame/HomeIntro.dart';
import 'package:frontend_ecotrack/presentation/user_app/profile/ProfileScreen.dart';
import 'package:frontend_ecotrack/presentation/user_app/switch_tabs/UserLayout.dart';
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
        return MaterialPageRoute(builder: (_) => Userlayout());
      case '/otp':
        final email = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => OtpScreenSingle(email: email));
      case '/QR_check':
        return MaterialPageRoute(builder: (context) => CheckIn_screen());
      case '/minigame':
        final args = settings.arguments as Map<String, dynamic>?;

        // Lấy quizId, userId từ args, nếu thiếu thì gán default
        final int quizId = (args?['quizId'] as int?) ?? 1; // default 1
        final int userId = (args?['userId'] as int?) ?? 0; // default 0

        return MaterialPageRoute(
          builder: (context) => HomeQuiz(quizId: quizId, userId: userId),
        );

      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text("Page not found"))),
        );
    }
  }
}
