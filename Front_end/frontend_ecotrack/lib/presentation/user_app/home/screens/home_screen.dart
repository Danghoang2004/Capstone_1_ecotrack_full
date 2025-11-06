import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/header.dart';
import '../widgets/welcome_card.dart';
import '../controllers/home_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Tạo controller chính tổng hợp
    final homeController = HomeController();

    return Scaffold(
      backgroundColor: HomeColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            HeaderWidget(controller: homeController.profileController),

            // Welcome Card
            WelcomeCard(controller: homeController.welcomeCardController),

            // Phần Nội dung
            Expanded(
              child: Container(
                color: HomeColors.background,
                child: const Center(child: Text('Nội dung')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
