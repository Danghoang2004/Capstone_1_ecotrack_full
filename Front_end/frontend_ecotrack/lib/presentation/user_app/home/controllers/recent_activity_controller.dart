import 'package:flutter/material.dart';

// Recent Activity Controller - Quản lý hoạt động gần đây
class RecentActivityModel {
  final String id;
  final String title;
  final String description; // "+50 Điểm - 2 giờ trước"
  final String iconType; // 'check', 'person', 'badge'
  final Color iconBgColor; // Màu nền icon

  RecentActivityModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconType,
    required this.iconBgColor,
  });
}

class RecentActivityController {
  // Mock data cho hoạt động gần đây
  List<RecentActivityModel> get activities => [
    RecentActivityModel(
      id: '1',
      title: 'Báo cáo rác thành công',
      description: '+50 Điểm - 2 giờ trước',
      iconType: 'check',
      iconBgColor: const Color(0xFFC0E1AE), // Xanh nhạt
    ),
    RecentActivityModel(
      id: '2',
      title: 'Tham gia chiến dịch',
      description: '+50 Điểm - 2 giờ trước',
      iconType: 'person',
      iconBgColor: const Color(0xFFC0E1AE), // Xanh nhạt
    ),
    RecentActivityModel(
      id: '3',
      title: 'Đạt huy hiệu mới',
      description: '+50 Điểm - 2 giờ trước',
      iconType: 'badge',
      iconBgColor: const Color(0xFFD4A574), // Nâu nhạt
    ),
  ];
}
