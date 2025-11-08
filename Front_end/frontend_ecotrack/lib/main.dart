import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/presentation/router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EcoTrack',
      theme: ThemeData(
        fontFamily: 'Arial',
        scaffoldBackgroundColor: const Color(0xFFF7F8F2),
      ),
      initialRoute: '/login',
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
