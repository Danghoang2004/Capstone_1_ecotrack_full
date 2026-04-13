class EnvironmentMyTeamInfo {
  final int teamId;
  final String teamName;
  final String teamDescription;
  final String myRoleInTeam;
  final int? leadUserId;
  final String leadFullName;
  final int memberCount;

  EnvironmentMyTeamInfo({
    required this.teamId,
    required this.teamName,
    required this.teamDescription,
    required this.myRoleInTeam,
    required this.leadUserId,
    required this.leadFullName,
    required this.memberCount,
  });

  factory EnvironmentMyTeamInfo.fromJson(Map<String, dynamic> json) {
    return EnvironmentMyTeamInfo(
      teamId: (json['teamId'] ?? 0) as int,
      teamName: (json['teamName'] ?? 'Chưa có đội') as String,
      teamDescription: (json['teamDescription'] ?? '') as String,
      myRoleInTeam: (json['myRoleInTeam'] ?? 'MEMBER') as String,
      leadUserId: json['leadUserId'] == null
          ? null
          : (json['leadUserId'] as num).toInt(),
      leadFullName: (json['leadFullName'] ?? 'Chưa xác định') as String,
      memberCount: (json['memberCount'] ?? 0) as int,
    );
  }
}
