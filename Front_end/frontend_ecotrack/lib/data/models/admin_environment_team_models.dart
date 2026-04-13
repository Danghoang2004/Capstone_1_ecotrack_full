class EnvironmentTeamMember {
  final int userId;
  final String fullName;
  final String username;
  final String email;
  final String role;

  EnvironmentTeamMember({
    required this.userId,
    required this.fullName,
    required this.username,
    required this.email,
    required this.role,
  });

  bool get isLead => role.toUpperCase() == 'LEAD';

  factory EnvironmentTeamMember.fromJson(Map<String, dynamic> json) {
    return EnvironmentTeamMember(
      userId: (json['userId'] ?? json['id'] ?? 0) as int,
      fullName:
          (json['fullName'] ?? json['name'] ?? json['username'] ?? '')
              as String,
      username: (json['username'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      role: (json['role'] ?? '') as String,
    );
  }
}

class EnvironmentTeam {
  final int teamId;
  final String teamName;
  final String description;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final EnvironmentTeamMember? lead;
  final List<EnvironmentTeamMember> members;

  EnvironmentTeam({
    required this.teamId,
    required this.teamName,
    required this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.lead,
    required this.members,
  });

  factory EnvironmentTeam.fromJson(Map<String, dynamic> json) {
    final leadJson = json['lead'];
    final membersJson = (json['members'] as List<dynamic>? ?? const []);

    return EnvironmentTeam(
      teamId: (json['teamId'] ?? 0) as int,
      teamName: (json['teamName'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      isActive: (json['isActive'] ?? true) as bool,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()),
      lead: leadJson == null
          ? null
          : EnvironmentTeamMember.fromJson(
              (leadJson as Map).cast<String, dynamic>(),
            ),
      members: membersJson
          .map(
            (item) => EnvironmentTeamMember.fromJson(
              (item as Map).cast<String, dynamic>(),
            ),
          )
          .toList(),
    );
  }
}

class EnvironmentTeamKpi {
  final int teamId;
  final String teamName;
  final String fromAt;
  final String toAt;
  final int totalAssigned;
  final int totalCompletedPending;
  final int totalResolved;
  final double completionRate;
  final int? avgResolutionMinutes;

  EnvironmentTeamKpi({
    required this.teamId,
    required this.teamName,
    required this.fromAt,
    required this.toAt,
    required this.totalAssigned,
    required this.totalCompletedPending,
    required this.totalResolved,
    required this.completionRate,
    required this.avgResolutionMinutes,
  });

  factory EnvironmentTeamKpi.fromJson(Map<String, dynamic> json) {
    return EnvironmentTeamKpi(
      teamId: (json['teamId'] ?? 0) as int,
      teamName: (json['teamName'] ?? '') as String,
      fromAt: (json['fromAt'] ?? '') as String,
      toAt: (json['toAt'] ?? '') as String,
      totalAssigned: (json['totalAssigned'] ?? 0) as int,
      totalCompletedPending: (json['totalCompletedPending'] ?? 0) as int,
      totalResolved: (json['totalResolved'] ?? 0) as int,
      completionRate: (json['completionRate'] as num? ?? 0).toDouble(),
      avgResolutionMinutes: json['avgResolutionMinutes'] == null
          ? null
          : (json['avgResolutionMinutes'] as num).toInt(),
    );
  }
}

class EnvironmentTeamUserOption {
  final int userId;
  final String fullName;
  final String username;
  final String email;

  EnvironmentTeamUserOption({
    required this.userId,
    required this.fullName,
    required this.username,
    required this.email,
  });

  String get displayLabel =>
      '$fullName${username.isNotEmpty ? ' (@$username)' : ''}';

  factory EnvironmentTeamUserOption.fromJson(Map<String, dynamic> json) {
    return EnvironmentTeamUserOption(
      userId: (json['id'] ?? json['userId'] ?? 0) as int,
      fullName:
          (json['fullName'] ?? json['name'] ?? json['username'] ?? '')
              as String,
      username: (json['username'] ?? '') as String,
      email: (json['email'] ?? '') as String,
    );
  }
}
