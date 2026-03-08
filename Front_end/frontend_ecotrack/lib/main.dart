import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend_ecotrack/presentation/router.dart';
import 'package:frontend_ecotrack/core/services/session_service.dart';
import 'package:frontend_ecotrack/presentation/user_app/switch_tabs/ThemeService.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService(),
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: SessionService.navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'EcoTrack',
          themeMode: ThemeService().themeMode,
          theme: ThemeData(
            fontFamily: 'Arial',
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF6F7F5),
            cardColor: Colors.white,
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.black87),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF6F7F5),
              iconTheme: IconThemeData(color: Colors.black87),
              titleTextStyle: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),  
            ),
          ),
          darkTheme: ThemeData( 
            fontFamily: 'Arial',
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.white70),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF121212),
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          initialRoute: '/login',
          onGenerateRoute: AppRouter.generateRoute,
        );
      },
    );
  }
}
