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
  final int daysRemaining; // Thêm trường này
  final bool joined;

  CampaignModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.dateTime,
    required this.participants,
    required this.location,
    required this.rewardPoints,
    required this.daysRemaining,
    required this.joined,
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
      daysRemaining: json['daysRemaining'] ?? 0, // Map từ JSON
      joined: json['joined'] == true || json['isJoined'] == true,
    );
  }

  CampaignModel copyWith({
    int? id,
    String? title,
    String? description,
    String? imageUrl,
    String? dateTime,
    int? participants,
    String? location,
    int? rewardPoints,
    int? daysRemaining,
    bool? joined,
  }) {
    return CampaignModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      dateTime: dateTime ?? this.dateTime,
      participants: participants ?? this.participants,
      location: location ?? this.location,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      joined: joined ?? this.joined,
    );
  }
}
