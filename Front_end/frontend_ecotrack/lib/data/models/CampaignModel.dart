import 'package:frontend_ecotrack/core/services/api_client.dart';

class CampaignModel {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final String dateTime;
  final int participants;
  final String location;
  final int rewardPoints;

  CampaignModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.dateTime,
    required this.participants,
    required this.location,
    required this.rewardPoints,
  });

  factory CampaignModel.fromJson(Map<String, dynamic> json, ApiClient api) {
    return CampaignModel(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? "",
      imageUrl: api.buildImageUrl(json['imageUrl']),
      dateTime: json['dateTime'],
      participants: json['participants'] ?? 0,
      location: json['location'] ?? "",
      rewardPoints: json['rewardPoints'] ?? 0,
    );
  }
}
