class ProfileView {
  final int userId;
  final String fullName;
  final String avatarUrl;
  final String email;
  final String username;

  final String? location;
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

  ProfileView({
    required this.userId,
    required this.fullName,
    required this.avatarUrl,
    required this.email,
    required this.username,
    this.location,
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
  });

  factory ProfileView.fromJson(Map<String, dynamic> json) {
    return ProfileView(
      userId: json['userId'] ?? 0,
      fullName: json['fullName'] ?? "",
      avatarUrl: json['avatarUrl'] ?? "",
      email: json['email'] ?? "",
      username: json['username'] ?? "",
      location: json['location'],
      levelName: json['levelName'],
      levelIcon: json['levelIcon'],
      points: json['points'] ?? 0,
      minPoints: json['minPoints'] ?? 0,
      maxPoints: json['maxPoints'] ?? 100,
      reportCount: json['reportCount'] ?? 0,
      groupCount: json['groupCount'] ?? 0,
      rank: json['rank'],
      badges: (json['badges'] as List<dynamic>)
          .map((e) => BadgeModel.fromJson(e))
          .toList(),
      recentActivities: (json['recentActivities'] as List<dynamic>)
          .map((e) => ActivityModel.fromJson(e))
          .toList(),
    );
  }
}

class BadgeModel {
  final int badgeId;
  final String badgeName;
  final String? iconUrl;
  final String? description;
  final String? requirement;
  final String? awardedAt;

  BadgeModel({
    required this.badgeId,
    required this.badgeName,
    this.iconUrl,
    this.description,
    this.requirement,
    this.awardedAt,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      badgeId: json['badgeId'],
      badgeName: json['badgeName'],
      iconUrl: json['iconUrl'],
      description: json['description'],
      requirement: json['requirement'],
      awardedAt: json['awardedAt'],
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
