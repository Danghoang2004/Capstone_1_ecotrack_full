class ProfileView {
  final int userId;
  final String fullName;
  final String avatarUrl;
  final String email;
  final String username;

  final String? location;
  final String? phoneNumber; // Mới thêm
  final String? gender; // Mới thêm (M, F, O)
  final DateTime? birthDate; // Mới thêm

  final String? levelName;
  final String? levelIcon;

  final int points;
  final int minPoints;
  final int maxPoints;

  final int reportCount;
  final int groupCount;
  final int? rank;

  final List<BadgeModel> badges;
  final List<ActivityModel> recentActivities;
  final List<TopRankingModel>? topRankings;

  ProfileView({
    required this.userId,
    required this.fullName,
    required this.avatarUrl,
    required this.email,
    required this.username,
    this.location,
    this.phoneNumber,
    this.gender,
    this.birthDate,
    this.levelName,
    this.levelIcon,
    required this.points,
    required this.minPoints,
    required this.maxPoints,
    required this.reportCount,
    required this.groupCount,
    this.rank,
    required this.badges,
    required this.recentActivities,
    this.topRankings,
  });

  factory ProfileView.fromJson(Map<String, dynamic> json) {
    return ProfileView(
      userId: json['userId'] ?? 0,
      fullName: json['fullName'] ?? "",
      avatarUrl: json['avatarUrl'] ?? "",
      email: json['email'] ?? "",
      username: json['username'] ?? "",
      location: json['location'],

      // Map đúng với tên field bên Java trả về
      // Trong Java bạn đặt là phone_number nên JSON key sẽ là 'phone_number'
      phoneNumber: json['phone_number'] ?? json['phoneNumber'],
      gender: json['gender'],

      // Xử lý ngày tháng từ chuỗi yyyy-MM-dd
      birthDate: json['birthDate'] != null
          ? DateTime.tryParse(json['birthDate'].toString())
          : null,

      levelName: json['levelName'],
      levelIcon: json['levelIcon'],
      points: json['points'] ?? 0,
      minPoints: json['minPoints'] ?? 0,
      maxPoints: json['maxPoints'] ?? 100,
      reportCount: json['reportCount'] ?? 0,
      groupCount: json['groupCount'] ?? 0,
      rank: json['rank'],
      badges:
          (json['badges'] as List<dynamic>?)
              ?.map((e) => BadgeModel.fromJson(e))
              .toList() ??
          [],
      recentActivities:
          (json['recentActivities'] as List<dynamic>?)
              ?.map((e) => ActivityModel.fromJson(e))
              .toList() ??
          [],
      topRankings: json['topRankings'] != null
          ? (json['topRankings'] as List<dynamic>)
                .map((e) => TopRankingModel.fromJson(e))
                .toList()
          : null,
    );
  }
}

class TopRankingModel {
  final String id;
  final int rank;
  final String userName;
  final int points;
  final String? avatarUrl;
  final String? location;
  final List<String> titles;

  TopRankingModel({
    required this.id,
    required this.rank,
    required this.userName,
    required this.points,
    this.avatarUrl,
    this.location,
    required this.titles,
  });

  factory TopRankingModel.fromJson(Map<String, dynamic> json) {
    return TopRankingModel(
      id: json['id']?.toString() ?? '',
      rank: json['rank'] ?? 0,
      userName: json['userName'] ?? '',
      points: json['points'] ?? 0,
      avatarUrl: json['avatarUrl'],
      location: json['location'],
      titles: json['titles'] != null ? List<String>.from(json['titles']) : [],
    );
  }
}

class BadgeModel {
  final int badgeId;
  final String badgeName;
  final String? iconUrl;
  final String? description;
  final String? requirement;
  final int pointsRequired;
  final String? awardedAt;
  final bool isClaimed;

  BadgeModel({
    required this.badgeId,
    required this.badgeName,
    this.iconUrl,
    this.description,
    this.requirement,
    required this.pointsRequired,
    this.awardedAt,
    required this.isClaimed,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      badgeId: json['badgeId'],
      badgeName: json['badgeName'],
      iconUrl: json['iconUrl'],
      description: json['description'],
      requirement: json['requirement'],
      pointsRequired: json['pointsRequired'] ?? 0,
      awardedAt: json['awardedAt'],
      isClaimed: json['isClaimed'] ?? (json['awardedAt'] != null),
    );
  }
}

class ActivityModel {
  final int transactionId;
  final String actionType;
  final int points;
  final String description;
  final String createdAt;

  ActivityModel({
    required this.transactionId,
    required this.actionType,
    required this.points,
    required this.description,
    required this.createdAt,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      transactionId: json['transactionId'],
      actionType: json['actionType'],
      points: json['points'],
      description: json['description'],
      createdAt: json['createdAt'],
    );
  }
}
