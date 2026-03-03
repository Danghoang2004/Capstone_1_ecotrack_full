import 'package:frontend_ecotrack/core/services/api_client.dart';

class UserCouponItem {
  final int userCouponId;
  final int couponId;
  final String title;
  final String description;
  final String partnerName;
  final String? imageUrl;
  final String status;
  final String expiryDate;
  final String? usedAt;

  UserCouponItem({
    required this.userCouponId,
    required this.couponId,
    required this.title,
    required this.description,
    required this.partnerName,
    this.imageUrl,
    required this.status,
    required this.expiryDate,
    this.usedAt,
  });

  factory UserCouponItem.fromJson(
      Map<String, dynamic> json, ApiClient api) {
    return UserCouponItem(
      userCouponId: json['userCouponId'] as int,
      couponId: json['couponId'] as int,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      partnerName: json['partnerName'] ?? '',
      imageUrl: api.buildImageUrl(json['thumbnailUrl']),
      status: json['status'].toString(),
      expiryDate: json['expiryDate'].toString(),
      usedAt: json['usedAt']?.toString(),
    );
  }

  bool get isUsed => status == 'USED';
  bool get isExpired => status == 'EXPIRED';
  bool get isUnused => status == 'UNUSED';
}
