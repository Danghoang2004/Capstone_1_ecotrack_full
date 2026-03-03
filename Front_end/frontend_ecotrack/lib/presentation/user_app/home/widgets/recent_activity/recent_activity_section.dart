import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../controllers/recent_activity_controller.dart';
import 'recent_activity_card.dart';

class RecentActivitySection extends StatelessWidget {
  final RecentActivityController controller;

  const RecentActivitySection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Hoạt Động Gần Đây',
            style: TextStyle(
              color: AppColors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Activity cards container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor, width: 1),
            ),
            child: Column(
              children: controller.activities
                  .map((activity) => RecentActivityCard(activity: activity))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
