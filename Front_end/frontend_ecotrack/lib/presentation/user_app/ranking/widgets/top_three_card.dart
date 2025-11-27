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
          (isGroup && groupRanking != null) ||
              (!isGroup && ranking != null),
          'Must provide ranking or groupRanking based on isGroup',
        );

  Color _getBarColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // Vàng cho rank 1
      case 2:
        return Colors.orange; // Cam cho rank 2
      case 3:
        return Colors.grey; // Xám cho rank 3
      default:
        return Colors.grey;
    }
  }

  Color _getBorderColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFEFEB0A); // Vàng cho top 1
      case 2:
        return const Color(0xFFD9D9D9); // Xám cho top 2
      case 3:
        return const Color(0xFFEBAB51); // Cam cho top 3
      default:
        return Colors.grey;
    }
  }



  @override
  Widget build(BuildContext context) {
    final rank = isGroup ? groupRanking!.rank : ranking!.rank;
    final name = isGroup ? groupRanking!.groupName : ranking!.userName;
    final points = isGroup ? groupRanking!.points : ranking!.points;
    final avatarUrl = isGroup ? groupRanking!.logoUrl : ranking!.avatarUrl;

    final isFirst = rank == 1;
    final cardHeight = isFirst ? 180.0 : 160.0;
    final avatarSize = isFirst ? 80.0 : 70.0;

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
              // Avatar
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[300],
                      border: Border.all(
                        color: _getBorderColor(rank),
                        width: 3,
                      ),
                    ),
                    child: avatarUrl != null && avatarUrl.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.grey,
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Tên
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              // Điểm
              Text(
                '${FormatNumber.formatPoints(points)} điểm',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                ),
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

