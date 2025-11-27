import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class RewardCard extends StatelessWidget {
  const RewardCard({super.key});

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
                color: const Color(0xFFE0F2F1), // Màu teal nhạt
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF4DB6AC), // Màu teal
                  width: 2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.card_giftcard,
                  color: Color(0xFF4DB6AC), // Màu teal
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Title
            const Text(
              'Đổi thưởng',
              style: TextStyle(
                color: AppColors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            // Subtitle
            const Text(
              'Coupon & Ưu đãi',
              style: TextStyle(color: AppColors.black, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
