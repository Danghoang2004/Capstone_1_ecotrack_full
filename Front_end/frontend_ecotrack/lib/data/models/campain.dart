import 'package:frontend_ecotrack/core/services/api_client.dart';

class Campaign {
  final int id;
  final String title;
  final String location;
  final String startDate;
  final String endDate;
  final int maxParticipants;
  final int rewardPoints;
  final int currentParticipants;
  final String? description;
  final String? imageUrl;
  final String? qrCodeUrl;
  final String? partnerName;

  Campaign({
    required this.id,
    required this.title,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.maxParticipants,
    required this.rewardPoints,
    required this.currentParticipants,

    this.description,
    this.imageUrl,
    this.qrCodeUrl,
    this.partnerName,
  });

  factory Campaign.fromJson(Map<String, dynamic> json, ApiClient api) {
    return Campaign(
      id: json['campaignId'],
      title: json['title'],
      description: json['description'],
      location: json['locationAddress'],
      startDate: json['startDate'].toString(),
      endDate: json['endDate'].toString(),
      maxParticipants: json['maxParticipants'] ?? 0,
      currentParticipants: json['currentParticipants'] ?? 0,
      rewardPoints: json['rewardPoints'] ?? 0,
      imageUrl: api.buildImageUrl(json['imageUrl']),
      qrCodeUrl: api.buildImageUrl(json['qrCodeUrl']),
      partnerName: json['partnerName'],
    );
  }
}
