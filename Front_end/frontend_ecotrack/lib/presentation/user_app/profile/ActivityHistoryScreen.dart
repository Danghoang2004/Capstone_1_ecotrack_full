import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/data/models/ProfileView.dart';
import '../../../core/services/user_service.dart' hide UnauthorizedException;
import 'package:frontend_ecotrack/core/errors/unauthorized_exception.dart';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  // Dùng Future để gọi API
  late Future<ProfileView> _viewFuture;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    // Gọi API lấy dữ liệu ngay khi màn hình khởi tạo
    _viewFuture = _userService.getProfileView();
  }

  // format thời gian
  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(dateString);
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    } catch (_) {
      return dateString;
    }
  }

  String _timeAgo(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(dateString);
      final diff = DateTime.now().difference(dateTime);

      if (diff.inMinutes < 1) return 'Vừa xong';
      if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
      if (diff.inHours < 24) return '${diff.inHours} giờ trước';
      return '${diff.inDays} ngày trước';
    } catch (_) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bgLight = Color(0xFFF4F9F4);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: bgLight,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Lịch sử hoạt động",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<ProfileView>(
        future: _viewFuture,
        builder: (context, snap) {
          // Đang tải
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            );
          }

          // Có lỗi
          if (snap.hasError) {
            final error = snap.error;
            if (error is UnauthorizedException) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacementNamed(context, '/login');
              });
              return const Center(
                child: Text('Phiên đăng nhập hết hạn, vui lòng đăng nhập lại.'),
              );
            }
            return Center(
              child: Text("Đã có lỗi xảy ra: ${error.toString()}"),
            );
          }

          // Thành công nhưng không có data
          final view = snap.data;
          if (view == null || view.recentActivities.isEmpty) {
            return _buildEmptyState();
          }

          // Render danh sách
          final activities = view.recentActivities;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Tất cả hoạt động (${activities.length})",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Icon(Icons.filter_list, color: Colors.grey.shade700, size: 20),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: activities.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildActivityItem(activities[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "Bạn chưa có hoạt động nào",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(ActivityModel activity) {
    final isGain = activity.points >= 0;
    final pointsText = "${isGain ? '+' : ''}${activity.points} điểm";
    
    IconData iconData = Icons.history;
    Color iconColor = const Color(0xFF5EAC24); 

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(iconData, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600, height: 1.3),
                ),
                const SizedBox(height: 6),
                Text(
                  "${_formatDate(activity.createdAt)} • ${_timeAgo(activity.createdAt)}",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isGain ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              pointsText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isGain ? Colors.green.shade800 : Colors.red.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}