import 'package:frontend_ecotrack/core/services/api_client.dart';

class CampaignDetailModel {
  final int id;
  final String title;
  final String description;
  final String imageUrl;

  final String location;
  final String startDate;
  final String endDate;
  final String timeRange;

  final int maxParticipants;
  final int participantCount;

  final int likeCount;
  final int commentCount;
  final int rewardPoints;

  final bool joined;
  final bool liked;

  CampaignDetailModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.timeRange,
    required this.maxParticipants,
    required this.participantCount,
    required this.likeCount,
    required this.commentCount,
    required this.rewardPoints,
    required this.joined,
    required this.liked,
  });

  factory CampaignDetailModel.fromJson(
    Map<String, dynamic> json,
    ApiClient api,
  ) {
    return CampaignDetailModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      imageUrl: api.buildImageUrl(json['imageUrl']),

      location: json['location'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      timeRange: json['timeRange'],

      maxParticipants: json['maxParticipants'],
      participantCount: json['participantCount'],

      likeCount: json['likeCount'],
      commentCount: json['commentCount'],
      rewardPoints: json['rewardPoints'],

      joined: json['joined'],
      liked: json['liked'],
    );
  }
}
