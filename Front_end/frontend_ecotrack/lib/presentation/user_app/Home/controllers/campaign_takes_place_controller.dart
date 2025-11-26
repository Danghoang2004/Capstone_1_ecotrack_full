// Campaign Takes Place Controller - Quản lý chiến dịch đang diễn ra
class CampaignModel {
  final String id;
  final String title;
  final String imageUrl;
  final String dateTime;
  final int participants;
  final String distance;

  CampaignModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.dateTime,
    required this.participants,
    required this.distance,
  });
}

class CampaignTakesPlaceController {
  // Mock data cho campaigns đang diễn ra
  List<CampaignModel> get campaigns => [
        CampaignModel(
          id: '1',
          title: 'Dọn rác bãi biển Đà Nẵng',
          imageUrl: 'assets/images/park_cleanup.jpg',
          dateTime: '16/07/2025 07:00-11:00',
          participants: 199,
          distance: '1.2km',
        ),
        CampaignModel(
          id: '2',
          title: 'Làm sạch công viên Tao Đàn',
          imageUrl: 'assets/images/park_cleanup.jpg',
          dateTime: '16/07/2025 07:00-11:00',
          participants: 199,
          distance: '1.2km',
        ),
      ];
}

