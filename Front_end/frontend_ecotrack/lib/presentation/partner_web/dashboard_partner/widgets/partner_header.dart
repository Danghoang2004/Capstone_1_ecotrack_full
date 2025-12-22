import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend_ecotrack/core/services/notification_service.dart';
import 'package:frontend_ecotrack/core/services/user_service.dart';
import 'package:frontend_ecotrack/data/models/NotificationModelAdmin.dart';
import 'package:frontend_ecotrack/data/models/ProfileView.dart';
import 'package:intl/intl.dart';

class PartnerHeader extends StatefulWidget {
  const PartnerHeader({super.key});

  @override
  State<PartnerHeader> createState() => _PartnerHeaderState();
}

class _PartnerHeaderState extends State<PartnerHeader> {
  final UserService _userService = UserService();
  final NotificationService _notification = NotificationService();
  final TextEditingController _searchController = TextEditingController();

  ProfileView? _profile;
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Tải song song profile và thông báo
    await Future.wait([_loadUserProfile(), _loadNotifications()]);
  }

  Future<void> _loadUserProfile() async {
    try {
      final p = await _userService.getProfileView();
      setState(() {
        _profile = p;
        _isLoadingProfile = false;
      });
    } catch (e) {
      debugPrint("Lỗi tải profile Partner: $e");
      setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final List<NotificationModel> list = await _notification
          .getPartnerNotifications();
      setState(() {
        _notifications = list;
        _unreadCount = list.where((n) => !n.isRead).length;
      });
    } catch (e) {
      debugPrint("Lỗi tải thông báo Partner: $e");
    }
  }

  Future<void> _markAsRead(int id) async {
    try {
      await _notification.markNotificationAsReadPartner(id);
      _loadNotifications();
    } catch (e) {
      debugPrint("Lỗi khi đánh dấu đã đọc: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final String fullImageUrl = _userService.apiClient.buildImageUrl(
      _profile?.avatarUrl,
    );

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildLogoSection(),
          const Spacer(),
          _buildSearchBox(),
          const Spacer(),
          _buildNotificationBell(),
          const SizedBox(width: 24),
          _buildProfileSection(fullImageUrl),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Row(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: const Color(0xFF5EAC24),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/images/Logo.svg',
              width: 20,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EcoTrack',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            Text(
              'Partner Portal',
              style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.0),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Search Box (Đã áp dụng fix lỗi lệch hàng)
  Widget _buildSearchBox() {
    return SizedBox(
      width: 400,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: TextField(
          controller: _searchController,
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(fontSize: 14),
          decoration: const InputDecoration(
            hintText: 'Tìm kiếm mọi thứ...',
            hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
            prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey),
            prefixIconConstraints: BoxConstraints(minWidth: 45, minHeight: 40),
            border: InputBorder.none,
            isCollapsed: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBell() {
    return PopupMenuButton<void>(
      offset: const Offset(0, 50),
      tooltip: "Thông báo",
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications_outlined,
            color: Colors.grey,
            size: 26,
          ),
          if (_unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    "Thông báo",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
                const Divider(),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: _notifications.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text("Chưa có thông báo"),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _notifications.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = _notifications[index];
                            return ListTile(
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: _getColor(
                                  item.type,
                                ).withOpacity(0.1),
                                child: Icon(
                                  _getIcon(item.type),
                                  size: 16,
                                  color: _getColor(item.type),
                                ),
                              ),
                              title: Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: item.isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                DateFormat(
                                  'HH:mm - dd/MM',
                                ).format(item.createdAt),
                                style: const TextStyle(fontSize: 11),
                              ),
                              onTap: () => _markAsRead(item.id),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection(String fullImageUrl) {
    if (_isLoadingProfile) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Row(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _profile?.fullName ?? "Đối tác",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              "Đối tác EcoTrack", // Thay đổi vai trò ở đây
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(width: 12),
        CircleAvatar(
          radius: 18,
          backgroundImage: (_profile?.avatarUrl != null)
              ? NetworkImage(fullImageUrl)
              : null,
          child: (_profile?.avatarUrl == null)
              ? const Icon(Icons.person)
              : null,
        ),
      ],
    );
  }

  Color _getColor(NotificationType type) {
    if (type == NotificationType.SYSTEM) return Colors.red;
    if (type == NotificationType.CAMPAIGN) return Colors.green;
    return Colors.blue;
  }

  IconData _getIcon(NotificationType type) {
    if (type == NotificationType.SYSTEM) return Icons.warning_amber_rounded;
    if (type == NotificationType.CAMPAIGN) return Icons.event_available;
    return Icons.notifications;
  }
}
