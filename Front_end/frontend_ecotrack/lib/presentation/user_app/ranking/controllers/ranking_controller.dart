// Ranking Controller - Quản lý bảng xếp hạng
import 'package:frontend_ecotrack/core/services/ranking_service.dart';

class RankingUserModel {
  final String id;
  final int rank;
  final String userName;
  final int points;
  final String? avatarUrl;
  final String location;
  final List<String> titles; // Đổi thành List để có thể có nhiều badge
  final int activities;
  final int badges;

  RankingUserModel({
    required this.id,
    required this.rank,
    required this.userName,
    required this.points,
    this.avatarUrl,
    required this.location,
    required this.titles,
    required this.activities,
    required this.badges,
  });

  factory RankingUserModel.fromJson(Map<String, dynamic> json) {
    return RankingUserModel(
      id: json['id']?.toString() ?? '',
      rank: json['rank'] ?? 0,
      userName: json['userName'] ?? '',
      points: json['points'] ?? 0,
      avatarUrl: json['avatarUrl'],
      location: json['location'] ?? '',
      titles: json['titles'] != null
          ? List<String>.from(json['titles'])
          : [],
      activities: json['activities'] ?? 0,
      badges: json['badges'] ?? 0,
    );
  }
}

class RankingGroupModel {
  final String id;
  final int rank;
  final String groupName;
  final int points;
  final String? logoUrl;
  final String location;
  final List<String> titles; // Thêm titles cho nhóm
  final int members;
  final int activities;

  RankingGroupModel({
    required this.id,
    required this.rank,
    required this.groupName,
    required this.points,
    this.logoUrl,
    required this.location,
    required this.titles,
    required this.members,
    required this.activities,
  });

  factory RankingGroupModel.fromJson(Map<String, dynamic> json) {
    return RankingGroupModel(
      id: json['id']?.toString() ?? '',
      rank: json['rank'] ?? 0,
      groupName: json['groupName'] ?? '',
      points: json['points'] ?? 0,
      logoUrl: json['logoUrl'],
      location: json['location'] ?? '',
      titles: json['titles'] != null
          ? List<String>.from(json['titles'])
          : [],
      members: json['members'] ?? 0,
      activities: json['activities'] ?? 0,
    );
  }
}

class RankingController {
  final RankingService _rankingService = RankingService();

  List<RankingUserModel> _individualRankings = [];
  List<RankingGroupModel> _groupRankings = [];
  bool _isLoadingIndividual = false;
  bool _isLoadingGroup = false;
  String? _errorIndividual;
  String? _errorGroup;

  List<RankingUserModel> get individualRankings => _individualRankings;
  List<RankingGroupModel> get groupRankings => _groupRankings;
  bool get isLoadingIndividual => _isLoadingIndividual;
  bool get isLoadingGroup => _isLoadingGroup;
  String? get errorIndividual => _errorIndividual;
  String? get errorGroup => _errorGroup;

  // Lấy top 3 cá nhân
  List<RankingUserModel> get topThreeIndividuals =>
      _individualRankings.take(3).toList();

  // Lấy danh sách từ hạng 4 trở đi (cá nhân)
  List<RankingUserModel> get remainingIndividuals =>
      _individualRankings.skip(3).toList();

  // Lấy top 3 nhóm
  List<RankingGroupModel> get topThreeGroups =>
      _groupRankings.take(3).toList();

  // Lấy danh sách từ hạng 4 trở đi (nhóm)
  List<RankingGroupModel> get remainingGroups =>
      _groupRankings.skip(3).toList();

  Future<void> loadIndividualRankings() async {
    _isLoadingIndividual = true;
    _errorIndividual = null;
    try {
      final data = await _rankingService.getIndividualRankings();
      _individualRankings = data
          .map((json) => RankingUserModel.fromJson(json))
          .toList();
    } catch (e) {
      // Nếu có 401, ApiClient đã xử lý (hiển thị dialog session expired)
      // Không cần hiển thị error message nữa
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        _errorIndividual = null; // Không set error để không hiển thị error message
      } else {
        _errorIndividual = e.toString();
      }
      _individualRankings = [];
    } finally {
      _isLoadingIndividual = false;
    }
  }

  Future<void> loadGroupRankings() async {
    _isLoadingGroup = true;
    _errorGroup = null;
    try {
      final data = await _rankingService.getGroupRankings();
      _groupRankings = data
          .map((json) => RankingGroupModel.fromJson(json))
          .toList();
    } catch (e) {
      // Nếu có 401, ApiClient đã xử lý (hiển thị dialog session expired)
      // Không cần hiển thị error message nữa
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        _errorGroup = null; // Không set error để không hiển thị error message
      } else {
        _errorGroup = e.toString();
      }
      _groupRankings = [];
    } finally {
      _isLoadingGroup = false;
    }
  }
}

