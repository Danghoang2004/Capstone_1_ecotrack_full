// Campaign Controller - Quản lý campaigns
class CampaignModel {
  final String id;
  final String title;
  final String imageUrl;
  final String dateTime;
  final int participants;
  final double distance;

  CampaignModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.dateTime,
    required this.participants,
    required this.distance,
  });
}

class CampaignController {
  // Mock data cho campaigns
  List<CampaignModel> get campaigns => [
        CampaignModel(
          id: '1',
          title: 'Dọn rác bãi biển Đà Nẵng',
          imageUrl:
              'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=400',
          dateTime: '16/07/2025 07:00-11:00',
          participants: 199,
          distance: 1.2,
        ),
        CampaignModel(
          id: '2',
          title: 'Làm sạch công viên Tao Đàn',
          imageUrl:
              'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400',
          dateTime: '16/07/2025 07:00-11:00',
          participants: 199,
          distance: 1.2,
        ),
      ];
}
