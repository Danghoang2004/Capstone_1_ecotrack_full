class CampaignChatMessage {
  final int messageId;
  final int campaignId;
  final int senderUserId;
  final String senderFullName;
  final String senderUsername;
  final String senderAvatarUrl;
  final String message;
  final String attachmentUrl;
  final String attachmentType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool mine;

  CampaignChatMessage({
    required this.messageId,
    required this.campaignId,
    required this.senderUserId,
    required this.senderFullName,
    required this.senderUsername,
    required this.senderAvatarUrl,
    required this.message,
    required this.attachmentUrl,
    required this.attachmentType,
    required this.createdAt,
    required this.updatedAt,
    required this.mine,
  });

  bool get hasAttachment => attachmentUrl.trim().isNotEmpty;
  bool get isImageAttachment =>
      attachmentType.toLowerCase().startsWith('image/');

  factory CampaignChatMessage.fromJson(Map<String, dynamic> json) {
    return CampaignChatMessage(
      messageId: (json['messageId'] ?? 0) as int,
      campaignId: (json['campaignId'] ?? 0) as int,
      senderUserId: (json['senderUserId'] ?? 0) as int,
      senderFullName: (json['senderFullName'] ?? 'Thành viên') as String,
      senderUsername: (json['senderUsername'] ?? '') as String,
      senderAvatarUrl: (json['senderAvatarUrl'] ?? '') as String,
      message: (json['message'] ?? '') as String,
      attachmentUrl: (json['attachmentUrl'] ?? '') as String,
      attachmentType: (json['attachmentType'] ?? '') as String,
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
          DateTime.now(),
      mine: (json['mine'] ?? false) as bool,
    );
  }
}
