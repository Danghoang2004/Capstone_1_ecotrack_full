import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/user_service.dart';
import 'package:frontend_ecotrack/data/models/ProfileView.dart';

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
  final UserService _userService = UserService();
  List<RecentActivityModel> _activities = [];
  bool _isLoading = false;
  String? _error;

  List<RecentActivityModel> get activities => _activities;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadActivities() async {
    _isLoading = true;
    _error = null;
    try {
      final profile = await _userService.getProfileView();
      _activities = profile.recentActivities
          .map((activity) => convertActivityToModel(activity))
          .toList();
    } catch (e) {
      _error = e.toString();
      _activities = [];
    } finally {
      _isLoading = false;
    }
  }

  // Static method để convert từ ActivityModel sang RecentActivityModel (dùng chung cho home và profile)
  static RecentActivityModel convertActivityToModel(ActivityModel activity) {
    // Map actionType thành iconType
    String iconType;
    Color iconBgColor;

    switch (activity.actionType.toUpperCase()) {
      case 'REPORT':
        iconType = 'check';
        iconBgColor = const Color(0xFFC0E1AE); // Xanh nhạt
        break;
      case 'CAMPAIGN':
        iconType = 'person';
        iconBgColor = const Color(0xFFC0E1AE); // Xanh nhạt
        break;
      case 'BADGE':
        iconType = 'badge';
        iconBgColor = const Color(0xFFD4A574); // Nâu nhạt
        break;
      default:
        iconType = 'check';
        iconBgColor = const Color(0xFFC0E1AE);
    }

    // Format description: "+X điểm • thời gian"
    final description =
        "+${activity.points} điểm • ${_formatDate(activity.createdAt)}";

    return RecentActivityModel(
      id: activity.transactionId.toString(),
      title: activity.description,
      description: description,
      iconType: iconType,
      iconBgColor: iconBgColor,
    );
  }

  static String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} ngày trước';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} giờ trước';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} phút trước';
      } else {
        return 'Vừa xong';
      }
    } catch (e) {
      return dateString;
    }
  }
}
