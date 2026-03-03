import 'package:flutter/material.dart';
import '../controllers/ranking_controller.dart';
import 'ranking_list_card.dart';

class RankingListSection extends StatelessWidget {
  final RankingController controller;
  final bool isIndividual;

  const RankingListSection({
    super.key,
    required this.controller,
    required this.isIndividual,
  });

  @override
  Widget build(BuildContext context) {
    if (isIndividual) {
      // Kiểm tra loading state
      if (controller.isLoadingIndividual) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Kiểm tra error
      if (controller.errorIndividual != null) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: Text(
              'Lỗi: ${controller.errorIndividual}',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        );
      }

      final allRankings = controller.individualRankings;

      if (allRankings.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: Text('Chưa có dữ liệu xếp hạng'),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: allRankings
              .map(
                (ranking) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: RankingListCard(ranking: ranking, isGroup: false),
                ),
              )
              .toList(),
        ),
      );
    } else {
      // Kiểm tra loading state
      if (controller.isLoadingGroup) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Kiểm tra error
      if (controller.errorGroup != null) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: Text(
              'Lỗi: ${controller.errorGroup}',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        );
      }

      final allRankings = controller.groupRankings;

      if (allRankings.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: Text('Chưa có dữ liệu xếp hạng'),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: allRankings
              .map(
                (groupRanking) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: RankingListCard(
                    groupRanking: groupRanking,
                    isGroup: true,
                  ),
                ),
              )
              .toList(),
        ),
      );
    }
  }
}
