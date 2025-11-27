import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/ranking_controller.dart';
import 'top_three_card.dart';

class TopThreeSection extends StatelessWidget {
  final RankingController controller;
  final bool isIndividual;

  const TopThreeSection({
    super.key,
    required this.controller,
    required this.isIndividual,
  });

  @override
  Widget build(BuildContext context) {
    if (isIndividual) {
      final topThree = controller.topThreeIndividuals;

      // Kiểm tra loading state
      if (controller.isLoadingIndividual) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Rank 2 (left)
              topThree.length > 1
                  ? TopThreeCard(ranking: topThree[1], isGroup: false)
                  : _buildEmptyCard(2),
              // Rank 1 (center - highest)
              topThree.length > 0
                  ? TopThreeCard(ranking: topThree[0], isGroup: false)
                  : _buildEmptyCard(1),
              // Rank 3 (right)
              topThree.length > 2
                  ? TopThreeCard(ranking: topThree[2], isGroup: false)
                  : _buildEmptyCard(3),
            ],
          ),
        ),
      );
    } else {
      final topThree = controller.topThreeGroups;

      // Kiểm tra loading state
      if (controller.isLoadingGroup) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Rank 2 (left)
              topThree.length > 1
                  ? TopThreeCard(groupRanking: topThree[1], isGroup: true)
                  : _buildEmptyCard(2),
              // Rank 1 (center - highest)
              topThree.length > 0
                  ? TopThreeCard(groupRanking: topThree[0], isGroup: true)
                  : _buildEmptyCard(1),
              // Rank 3 (right)
              topThree.length > 2
                  ? TopThreeCard(groupRanking: topThree[2], isGroup: true)
                  : _buildEmptyCard(3),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildEmptyCard(int rank) {
    final isFirst = rank == 1;
    final cardHeight = isFirst ? 180.0 : 160.0;
    final avatarSize = isFirst ? 80.0 : 70.0;

    Color _getBarColor(int rank) {
      switch (rank) {
        case 1:
          return Colors.amber;
        case 2:
          return Colors.orange;
        case 3:
          return Colors.grey;
        default:
          return Colors.grey;
      }
    }

    Color _getBorderColor(int rank) {
      switch (rank) {
        case 1:
          return const Color(0xFFEFEB0A);
        case 2:
          return const Color(0xFFD9D9D9);
        case 3:
          return const Color(0xFFEBAB51);
        default:
          return Colors.grey;
      }
    }

    return Column(
      children: [
        // Badge số hạng
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _getBarColor(rank),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Card
        Container(
          width: 100,
          height: cardHeight,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar placeholder
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                  border: Border.all(color: _getBorderColor(rank), width: 3),
                ),
                child: const Icon(Icons.person, size: 40, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              // Text "Chưa có"
              Text(
                'Chưa có',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              // Điểm placeholder
              Text(
                '0 điểm',
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
              const Spacer(),
              // Thanh màu
              Container(
                width: double.infinity,
                height: 4,
                decoration: BoxDecoration(
                  color: _getBarColor(rank),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
