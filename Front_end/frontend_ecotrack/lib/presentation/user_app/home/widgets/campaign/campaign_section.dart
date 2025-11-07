import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../controllers/campaign_controller.dart';
import 'campaign_card.dart';
import '../../../../common/widgets/flexible_layout.dart';

class CampaignSection extends StatelessWidget {
  final CampaignController controller;

  const CampaignSection({super.key, required this.controller});

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
                'Chiến dịch đang diễn ra',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Xem tất cả',
                style: TextStyle(color: AppColors.black, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Campaign cards
          FlexibleLayout(
            direction: 'column',
            spacing: 0,
            children: controller.campaigns
                .map((campaign) => CampaignCard(campaign: campaign))
                .toList(),
          ),
        ],
      ),
    );
  }
}
