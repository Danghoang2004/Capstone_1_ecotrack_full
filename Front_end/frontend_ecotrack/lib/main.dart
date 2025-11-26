import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/presentation/router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
