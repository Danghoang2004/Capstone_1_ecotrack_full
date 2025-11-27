import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../controllers/recent_activity_controller.dart';

class RecentActivityCard extends StatelessWidget {
  final RecentActivityModel activity;

  const RecentActivityCard({super.key, required this.activity});

  Widget _buildIcon(String iconType, Color bgColor) {
    IconData iconData;
    Color iconColor;

    switch (iconType) {
      case 'check':
        iconData = Icons.check;
        iconColor = const Color(0xFF3C9541); // Xanh đậm
        break;
      case 'person':
        iconData = Icons.person;
        iconColor = const Color(0xFF3C9541); // Xanh đậm
        break;
      case 'badge':
        iconData = Icons.star;
        iconColor = const Color(0xFF8B4513); // Nâu đậm
        break;
      default:
        iconData = Icons.circle;
        iconColor = AppColors.black;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(iconData, color: iconColor, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Icon
          _buildIcon(activity.iconType, activity.iconBgColor),
          const SizedBox(width: 12),
          // Title và description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
