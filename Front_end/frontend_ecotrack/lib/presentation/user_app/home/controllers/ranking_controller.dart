// Ranking Controller - Quản lý bảng xếp hạng
class RankingModel {
  final String id;
  final int rank;
  final String userName;
  final int points;
  final String? avatarUrl;

  RankingModel({
    required this.id,
    required this.rank,
    required this.userName,
    required this.points,
    this.avatarUrl,
  });
}

class RankingController {
  // Mock data cho bảng xếp hạng tuần
  List<RankingModel> get weeklyRankings => [
        RankingModel(
          id: '1',
          rank: 1,
          userName: 'Dương Văn Hùng',
          points: 2999,
        ),
        RankingModel(
          id: '2',
          rank: 2,
          userName: 'Dương Văn Hùng',
          points: 2999,
        ),
        RankingModel(
          id: '3',
          rank: 3,
          userName: 'Dương Văn Hùng',
          points: 2999,
        ),
        RankingModel(
          id: '4',
          rank: 4,
          userName: 'Dương Văn Hùng',
          points: 2999,
        ),
      ];
}
