import 'package:flutter/material.dart';
import '../controllers/ranking_controller.dart';
import '../../../common/formatNumber/format_number.dart';

class TopThreeCard extends StatelessWidget {
  final RankingUserModel? ranking;
  final RankingGroupModel? groupRanking;
  final bool isGroup;

  const TopThreeCard({
    super.key,
    this.ranking,
    this.groupRanking,
    required this.isGroup,
  }) : assert(
         (isGroup && groupRanking != null) || (!isGroup && ranking != null),
         'Must provide ranking or groupRanking based on isGroup',
       );

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
        return const Color(0xFFEFEB0A); // Vàng cho top 1
      case 2:
        return const Color(0xFFEBAB51); // Cam cho top 2
      case 3:
        return const Color(0xFFD9D9D9); // Xám cho top 3
      default:
        return Colors.grey;
    }
  }

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

  // Gradient cho cột dưới - DÙNG ĐÚNG MÀU
  LinearGradient _getPodiumGradient(int rank) {
    switch (rank) {
      case 1:
        // Top 1: Vàng #EFEB0A
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFF9C4), // Vàng rất nhạt
            Color(0xFFEFEB0A), // Vàng chính
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
            Color(0xFFEBAB51), // Cam chính
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
            Color(0xFFD9D9D9), // Xám chính
            Color(0xFFBDBDBD), // Xám đậm hơn
          ],
        );
      default:
        return LinearGradient(colors: [Colors.grey, Colors.grey]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rank = isGroup ? groupRanking!.rank : ranking!.rank;
    final name = isGroup ? groupRanking!.groupName : ranking!.userName;
    final points = isGroup ? groupRanking!.points : ranking!.points;
    final avatarUrl = isGroup ? groupRanking!.logoUrl : ranking!.avatarUrl;

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;
    final isFirst = rank == 1;
    final avatarSize = isFirst ? 70.0 : 60.0;
    final podiumWidth = isDesktop ? 80.0 : double.infinity;

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
        // Avatar
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[300],
            border: Border.all(color: _getBorderColor(rank), width: 3),
          ),
          child: avatarUrl != null && avatarUrl.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.person,
                      size: avatarSize * 0.5,
                      color: Colors.grey,
                    ),
                  ),
                )
              : Icon(Icons.person, size: avatarSize * 0.5, color: Colors.grey),
        ),
        const SizedBox(height: 6),
        // Tên
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            height: 1.15,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 2),
        // Điểm
        Text(
          '${FormatNumber.formatPoints(points)} điểm',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
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
