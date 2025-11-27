import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class MiniGameCard extends StatelessWidget {
  const MiniGameCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: HomeColors.cardBorder,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderColor, width: 2),
              ),
              child: const Center(
                child: Icon(
                  Icons.sports_esports,
                  color: AppColors.black,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Title
            const Text(
              'Mini Game',
              style: TextStyle(
                color: AppColors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            // Subtitle
            const Text(
              'Quiz môi trường',
              style: TextStyle(color: AppColors.black, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
