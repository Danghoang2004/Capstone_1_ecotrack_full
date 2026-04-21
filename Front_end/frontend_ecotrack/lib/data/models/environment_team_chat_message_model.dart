class EnvironmentTeamChatMessage {
  final int messageId;
  final int teamId;
  final int senderUserId;
  final String senderFullName;
  final String senderUsername;
  final String senderAvatarUrl;
  final String message;
  final DateTime sentAt;
  final bool mine;
  final String messageType;
  final String attachmentUrl;
  final String attachmentName;
  final String attachmentMimeType;
  final int attachmentSizeBytes;
  final int seenByCount;
  final int totalMemberCount;
  final bool seenByAll;

  EnvironmentTeamChatMessage({
    required this.messageId,
    required this.teamId,
    required this.senderUserId,
    required this.senderFullName,
    required this.senderUsername,
    required this.senderAvatarUrl,
    required this.message,
    required this.sentAt,
    required this.mine,
    required this.messageType,
    required this.attachmentUrl,
    required this.attachmentName,
    required this.attachmentMimeType,
    required this.attachmentSizeBytes,
    required this.seenByCount,
    required this.totalMemberCount,
    required this.seenByAll,
  });

  factory EnvironmentTeamChatMessage.fromJson(Map<String, dynamic> json) {
    return EnvironmentTeamChatMessage(
      messageId: (json['messageId'] ?? 0) as int,
      teamId: (json['teamId'] ?? 0) as int,
      senderUserId: (json['senderUserId'] ?? 0) as int,
      senderFullName: (json['senderFullName'] ?? 'Thành viên') as String,
      senderUsername: (json['senderUsername'] ?? '') as String,
      senderAvatarUrl: (json['senderAvatarUrl'] ?? '') as String,
      message: (json['message'] ?? '') as String,
      sentAt:
          DateTime.tryParse((json['sentAt'] ?? '').toString()) ??
          DateTime.now(),
      mine: (json['mine'] ?? false) as bool,
      messageType: (json['messageType'] ?? 'TEXT') as String,
      attachmentUrl: (json['attachmentUrl'] ?? '') as String,
      attachmentName: (json['attachmentName'] ?? '') as String,
      attachmentMimeType: (json['attachmentMimeType'] ?? '') as String,
      attachmentSizeBytes: (json['attachmentSizeBytes'] ?? 0) as int,
      seenByCount: (json['seenByCount'] ?? 0) as int,
      totalMemberCount: (json['totalMemberCount'] ?? 0) as int,
      seenByAll: (json['seenByAll'] ?? false) as bool,
    );
  }
}
