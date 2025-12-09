import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend_ecotrack/presentation/router.dart';
import 'package:frontend_ecotrack/core/services/session_service.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: SessionService.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'EcoTrack',
      theme: ThemeData(
        fontFamily: 'Arial',
        scaffoldBackgroundColor: const Color.fromARGB(255, 246, 247, 245),
      ),
      initialRoute: '/login',
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
