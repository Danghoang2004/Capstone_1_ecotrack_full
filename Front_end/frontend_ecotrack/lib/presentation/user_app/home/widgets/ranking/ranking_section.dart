import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../controllers/ranking_controller.dart';
import 'ranking_card.dart';

class RankingSection extends StatelessWidget {
  final RankingController controller;

  const RankingSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bảng Xếp Hạng Tuần',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Xem tất cả',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Ranking card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor, width: 1),
            ),
            child: Column(
              children: controller.weeklyRankings
                  .map((ranking) => RankingCard(ranking: ranking))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

