import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../controllers/ranking_controller.dart';
import '../../../../common/formatNumber/format_number.dart';

class RankingCard extends StatelessWidget {
  final RankingModel ranking;

  const RankingCard({super.key, required this.ranking});

  // Màu cho rank circle
  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // Vàng cho rank 1
      case 2:
        return Colors.grey[300]!; // Xanh nhạt cho rank 2
      case 3:
        return Colors.orange[300]!; // Cam nhạt cho rank 3
      default:
        return Colors.orange[600]!; // Cam đậm cho rank 4+
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Navigate to ranking screen
        Navigator.pushNamed(context, '/ranking');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Rank circle
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getRankColor(ranking.rank),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${ranking.rank}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: ranking.avatarUrl != null && ranking.avatarUrl!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        ranking.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.person,
                              color: Colors.grey,
                              size: 24,
                            ),
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.grey, size: 24),
            ),
            const SizedBox(width: 12),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ranking.userName,
                    style: const TextStyle(
                      color: AppColors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${FormatNumber.formatPoints(ranking.points)} điểm',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
