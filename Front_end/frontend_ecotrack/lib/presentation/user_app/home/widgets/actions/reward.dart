// reward.dart
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class RewardCard extends StatelessWidget {
  const RewardCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Expanded(
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isDesktop ? 64 : 56,
              height: isDesktop ? 64 : 56,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF4DB6AC), width: 2),
              ),
              child: Center(
                child: Icon(
                  Icons.card_giftcard,
                  color: const Color(0xFF4DB6AC),
                  size: isDesktop ? 32 : 28,
                ),
              ),
            ),
            SizedBox(height: isDesktop ? 16 : 12),
            Text(
              'Đổi thưởng',
              style: TextStyle(
                color: AppColors.black,
                fontSize: isDesktop ? 18 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isDesktop ? 8 : 4),
            Text(
              'Coupon & Ưu đãi',
              style: TextStyle(
                color: AppColors.black,
                fontSize: isDesktop ? 14 : 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
