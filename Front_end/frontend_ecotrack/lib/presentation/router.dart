import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/presentation/auth/LoginScreen.dart';
import 'package:frontend_ecotrack/presentation/user_app/Home/Home_screen.dart';
import 'package:frontend_ecotrack/presentation/user_app/Report/Report_page.dart';
import 'package:frontend_ecotrack/presentation/user_app/profile/ProfileScreen.dart';
import 'package:frontend_ecotrack/presentation/user_app/switch_tabs/UserLayout.dart';

import 'auth/register_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
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
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text("Page not found"))),
        );
    }
  }
}
