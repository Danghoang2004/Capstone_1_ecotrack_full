import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../controllers/ranking_controller.dart';
import 'ranking_card.dart';
import '../../../switch_tabs/UserLayout.dart';

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
              InkWell(
                onTap: () {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final isDesktop = screenWidth > 800;

                  if (isDesktop) {
                    // Desktop: Switch sang ranking screen trong UserLayout
                    Userlayout.switchToRanking(context);
                  } else {
                    // Mobile: push route mới
                    Navigator.pushNamed(context, '/ranking');
                  }
                },
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(color: AppColors.black, fontSize: 14),
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
            child: controller.isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : controller.error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Lỗi: ${controller.error}',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : controller.weeklyRankings.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Chưa có dữ liệu',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  )
                : Column(
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
