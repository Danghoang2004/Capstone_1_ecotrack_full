class EnvironmentTeamLead {
  final int userId;
  final String fullName;
  final String username;
  final String email;

  EnvironmentTeamLead({
    required this.userId,
    required this.fullName,
    required this.username,
    required this.email,
  });

  factory EnvironmentTeamLead.fromJson(Map<String, dynamic> json) {
    return EnvironmentTeamLead(
      userId: (json['userId'] ?? 0) as int,
      fullName: (json['fullName'] ?? '') as String,
      username: (json['username'] ?? '') as String,
      email: (json['email'] ?? '') as String,
    );
  }
}
