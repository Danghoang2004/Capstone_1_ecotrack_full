import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../controllers/ranking_controller.dart';
import '../../../common/formatNumber/format_number.dart';

class RankingListCard extends StatelessWidget {
  final RankingUserModel? ranking;
  final RankingGroupModel? groupRanking;
  final bool isGroup;

  const RankingListCard({
    super.key,
    this.ranking,
    this.groupRanking,
    required this.isGroup,
  }) : assert(
         (isGroup && groupRanking != null) || (!isGroup && ranking != null),
         'Must provide ranking or groupRanking based on isGroup',
       );

  Widget _buildBadge(int rank) {
    if (rank == 1) {
      // Huy hiệu vàng cho top 1
      return SvgPicture.asset('assets/icons/top1.svg', width: 32, height: 32);
    } else if (rank == 2) {
      // Huy hiệu bạc cho top 2
      return SvgPicture.asset('assets/icons/top2.svg', width: 32, height: 32);
    } else if (rank == 3) {
      // Huy hiệu đồng cho top 3
      return SvgPicture.asset('assets/icons/top3.svg', width: 32, height: 32);
    } else {
      // Số rank cho các hạng khác
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: rank == 4 ? Colors.red : Colors.green,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            '#$rank',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rank = isGroup ? groupRanking!.rank : ranking!.rank;
    final name = isGroup ? groupRanking!.groupName : ranking!.userName;
    final points = isGroup ? groupRanking!.points : ranking!.points;
    final avatarUrl = isGroup ? groupRanking!.logoUrl : ranking!.avatarUrl;
    final location = isGroup ? groupRanking!.location : ranking!.location;
    final titles = isGroup ? groupRanking!.titles : ranking!.titles;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade100, width: 1),
      ),
      child: Row(
        children: [
          // Huy hiệu/badge bên trái
          _buildBadge(rank),
          const SizedBox(width: 12),
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
            ),
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : const Icon(Icons.person, size: 30, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          // Thông tin
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                if (location.isNotEmpty)
                  Text(
                    location,
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                  ),
                if (titles.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: titles.map((title) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC0E1AE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF3C9541),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          // Điểm
          Text(
            '${FormatNumber.formatPoints(points)} Điểm',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3C9541),
            ),
          ),
        ],
      ),
    );
  }
}
