import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/notification_service.dart';
import 'package:frontend_ecotrack/presentation/user_app/notification/notification_detail_screen.dart';

/// Model 1 notification trong app
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String tag; // CAMPAIGN / ACHIEVEMENT / REWARD / SYSTEM
  final bool isRead;
  final String timeAgo; // tạm dùng createdAt string

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.tag,
    required this.isRead,
    required this.timeAgo,
  });

  /// Map từ JSON backend (NotificationResponse)
  /// {
  ///   "id": 1,
  ///   "title": "...",
  ///   "message": "...",
  ///   "type": "CAMPAIGN",
  ///   "read": false,
  ///   "createdAt": "2025-11-29T14:30:00"
  /// }
  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      tag: json['type'] ?? 'SYSTEM',
      isRead: json['read'] ?? false,
      timeAgo: json['createdAt']?.toString() ?? '',
    );
  }
}

class NotificationScreen extends StatefulWidget {
  static const routeName = '/notifications';

  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NotificationService _service = NotificationService();

  List<NotificationItem> _all = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final items = await _service.getAll();
      setState(() {
        _all = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Thông báo')),
        body: Center(child: Text('Lỗi: $_error')),
      );
    }

    final unread = _all.where((e) => !e.isRead).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7F5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Thông báo',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,

        // PHẦN QUAN TRỌNG ĐỂ KHUNG "Tất cả / Chưa đọc" NHỎ LẠI
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Padding(
              // ⬅️ Widget Padding được thêm để tạo khoảng cách 10px 2 bên
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
              ), // ⬅️ Khoảng cách 10px trái/phải
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F5D8),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: SizedBox(
                    height: 35, // Đã điều chỉnh để trông thon gọn hơn
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: false,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                      ), // Padding nội bộ của text trong Tab
                      labelColor: Colors.white,
                      unselectedLabelColor: const Color(0xFF2F6B2F),
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: const Color(0xFF2F6B2F),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      tabs: const [
                        Tab(child: Text('Tất cả')),
                        Tab(child: Text('Chưa đọc')),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildList(_all), _buildList(unread)],
      ),
    );
  }

  Widget _buildList(List<NotificationItem> items) {
    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) => _buildCard(items[index]),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: items.length,
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: const [
        SizedBox(height: 120),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 48, color: Color(0xFFB0C7A8)),
              SizedBox(height: 12),
              Text(
                'Không có thông báo nào',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5E8B5A),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Bạn đã đọc hết tất cả thông báo',
                style: TextStyle(color: Color(0xFF9BAF97)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard(NotificationItem item) {
    return InkWell(
      onTap: () async {
        // 1️⃣ Nếu chưa đọc → đánh dấu đã đọc
        if (!item.isRead) {
          try {
            await _service.markAsRead(item.id);

            setState(() {
              final idx = _all.indexWhere((n) => n.id == item.id);
              if (idx != -1) {
                _all[idx] = NotificationItem(
                  id: item.id,
                  title: item.title,
                  message: item.message,
                  tag: item.tag,
                  isRead: true,
                  timeAgo: item.timeAgo,
                );
              }
            });
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Không đánh dấu đã đọc được: $e')),
            );
          }
        }

        // 2️⃣ LUÔN mở màn hình chi tiết
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NotificationDetailScreen(item: item),
          ),
        );
      },

      child: Container(
        decoration: BoxDecoration(
          // 🔹 Giữ nguyên kiểu card bo tròn, viền nhạt
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5EDE2)),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // icon lá bên trái + chấm nếu chưa đọc
            Stack(
              children: [
                const Icon(Icons.eco_outlined, color: Color(0xFF3D7D3A)),
                if (!item.isRead)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF8BC34A),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // dòng trên: tag + thời gian (giữ nguyên tag)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F5D8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.tag,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF3D7D3A),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          item.timeAgo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF9BAF97),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // 🔸 Tiêu đề: chưa đọc đậm + màu đậm, đã đọc mảnh + nhạt hơn
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: item.isRead
                          ? FontWeight
                                .w500 // đã đọc
                          : FontWeight.w700, // chưa đọc – đậm hơn
                      color: item.isRead
                          ? Colors
                                .black54 // đã đọc – nhạt
                          : Colors.black87, // chưa đọc – đậm
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 🔸 Nội dung: đã đọc nhạt màu hơn
                  Text(
                    item.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: item.isRead
                          ? Colors
                                .black45 // đã đọc
                          : Colors.black87, // chưa đọc
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
