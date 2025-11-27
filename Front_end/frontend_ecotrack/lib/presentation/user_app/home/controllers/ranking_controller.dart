// Ranking Controller - Quản lý bảng xếp hạng
import 'package:frontend_ecotrack/core/services/ranking_service.dart';

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

  factory RankingModel.fromJson(Map<String, dynamic> json) {
    return RankingModel(
      id: json['id']?.toString() ?? '',
      rank: json['rank'] ?? 0,
      userName: json['userName'] ?? '',
      points: json['points'] ?? 0,
      avatarUrl: json['avatarUrl'],
    );
  }
}

class RankingController {
  final RankingService _rankingService = RankingService();
  
  List<RankingModel> _weeklyRankings = [];
  bool _isLoading = false;
  String? _error;

  List<RankingModel> get weeklyRankings => _weeklyRankings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadWeeklyRankings() async {
    _isLoading = true;
    _error = null;
    try {
      // Lấy top 4 từ API (hoặc có thể lấy top 5 rồi lấy 4 đầu)
      final data = await _rankingService.getIndividualRankings();
      _weeklyRankings = data
          .take(4) // Chỉ lấy 4 người đầu tiên cho home screen
          .map((json) => RankingModel.fromJson(json))
          .toList();
    } catch (e) {
      _error = e.toString();
      _weeklyRankings = [];
    } finally {
      _isLoading = false;
    }
  }
}
