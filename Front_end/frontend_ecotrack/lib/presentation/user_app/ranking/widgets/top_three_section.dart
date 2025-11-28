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
              Expanded(
                child: topThree.length > 1
                    ? TopThreeCard(ranking: topThree[1], isGroup: false)
                    : _buildEmptyCard(2, context),
              ),
              const SizedBox(width: 8),
              // Rank 1 (center - highest)
              Expanded(
                child: topThree.length > 0
                    ? TopThreeCard(ranking: topThree[0], isGroup: false)
                    : _buildEmptyCard(1, context),
              ),
              const SizedBox(width: 8),
              // Rank 3 (right)
              Expanded(
                child: topThree.length > 2
                    ? TopThreeCard(ranking: topThree[2], isGroup: false)
                    : _buildEmptyCard(3, context),
              ),
            ],
          ),
        ),
      );
    } else {
      final topThree = controller.topThreeGroups;

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
              Expanded(
                child: topThree.length > 1
                    ? TopThreeCard(groupRanking: topThree[1], isGroup: true)
                    : _buildEmptyCard(2, context),
              ),
              const SizedBox(width: 8),
              // Rank 1 (center - highest)
              Expanded(
                child: topThree.length > 0
                    ? TopThreeCard(groupRanking: topThree[0], isGroup: true)
                    : _buildEmptyCard(1, context),
              ),
              const SizedBox(width: 8),
              // Rank 3 (right)
              Expanded(
                child: topThree.length > 2
                    ? TopThreeCard(groupRanking: topThree[2], isGroup: true)
                    : _buildEmptyCard(3, context),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildEmptyCard(int rank, BuildContext? context) {
    final screenWidth = context != null ? MediaQuery.of(context).size.width : 0;
    final isDesktop = screenWidth > 800;
    final isFirst = rank == 1;
    final avatarSize = isFirst ? 70.0 : 60.0;
    final podiumWidth = isDesktop ? 80.0 : double.infinity;

    // Chiều cao cột dưới theo rank - TOP 1 PHẢI CAO NHẤT
    double _getPodiumHeight(int rank) {
      switch (rank) {
        case 1:
          return 80.0; // CAO NHẤT - TOP 1
        case 2:
          return 60.0; // Trung bình - TOP 2
        case 3:
          return 50.0; // Thấp nhất - TOP 3
        default:
          return 50.0;
      }
    }

    Color _getBadgeColor(int rank) {
      switch (rank) {
        case 1:
          return const Color(0xFFFFD700); // Vàng
        case 2:
          return const Color(0xFFFF8C00); // Cam
        case 3:
          return const Color(0xFF9E9E9E); // Xám
        default:
          return Colors.grey;
      }
    }

    Color _getBorderColor(int rank) {
      switch (rank) {
        case 1:
          return const Color(0xFFEFEB0A); // Màu vàng của bạn
        case 2:
          return const Color(0xFFEBAB51); // Màu cam của bạn
        case 3:
          return const Color(0xFFD9D9D9); // Màu xám của bạn
        default:
          return Colors.grey;
      }
    }

    // Gradient cho cột dưới - DÙNG ĐÚNG MÀU CỦA BẠN
    LinearGradient _getPodiumGradient(int rank) {
      switch (rank) {
        case 1:
          // Top 1: Vàng #EFEB0A
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF9C4), // Vàng rất nhạt
              Color(0xFFEFEB0A), // Vàng chính của bạn
              Color(0xFFD4D009), // Vàng đậm hơn
            ],
          );
        case 2:
          // Top 2: Cam #EBAB51
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFE0B2), // Cam nhạt
              Color(0xFFEBAB51), // Cam chính của bạn
              Color(0xFFD99746), // Cam đậm hơn
            ],
          );
        case 3:
          // Top 3: Xám #D9D9D9
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEEEEEE), // Xám rất nhạt
              Color(0xFFD9D9D9), // Xám chính của bạn
              Color(0xFFBDBDBD), // Xám đậm hơn
            ],
          );
        default:
          return LinearGradient(colors: [Colors.grey, Colors.grey]);
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Badge số hạng
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _getBadgeColor(rank),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _getBadgeColor(rank).withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Avatar placeholder
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[300],
            border: Border.all(color: _getBorderColor(rank), width: 3),
          ),
          child: Icon(Icons.person, size: avatarSize * 0.5, color: Colors.grey),
        ),
        const SizedBox(height: 6),
        // Text "Chưa có"
        Text(
          'Chưa có',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 2),
        // Điểm placeholder
        Text('0 điểm', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        const SizedBox(height: 8),
        // Cột đế (Podium) - ĐÚNG MÀU VÀ CHIỀU CAO
        Center(
          child: Container(
            width: podiumWidth,
            height: _getPodiumHeight(rank),
            decoration: BoxDecoration(
              gradient: _getPodiumGradient(rank),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
