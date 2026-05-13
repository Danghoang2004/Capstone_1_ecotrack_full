import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend_ecotrack/core/theme/app_colors.dart';
import 'package:frontend_ecotrack/core/services/notification_service.dart';
import 'package:frontend_ecotrack/core/services/user_service.dart';
import 'package:frontend_ecotrack/data/models/NotificationModelAdmin.dart';
import 'package:frontend_ecotrack/data/models/ProfileView.dart';
import 'package:intl/intl.dart';

class AdminHeader extends StatefulWidget {
  const AdminHeader({super.key});

  @override
  State<AdminHeader> createState() => _AdminHeaderState();
}

class _AdminHeaderState extends State<AdminHeader> {
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
    await Future.wait([_loadUserProfile(), _loadNotifications()]);
  }

  Future<void> _loadUserProfile() async {
    try {
      final p = await _userService.getProfileView();
      if (!mounted) return;
      setState(() {
        _profile = p;
        _isLoadingProfile = false;
      });
    } catch (e) {
      debugPrint("Lỗi tải profile: $e");
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  Future<void> _loadNotifications() async {
    try {
      // Giả sử bạn đã thêm hàm này vào UserService gọi tới API /api/admin/notifications
      final List<NotificationModel> list = await _notification
          .getAdminNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = list;
        _unreadCount = list.where((n) => !n.isRead).length;
      });
    } catch (e) {
      debugPrint("Lỗi tải thông báo: $e");
    }
  }

  Future<void> _markAsRead(int id) async {
    try {
      await _notification.markNotificationAsRead(id);
      _loadNotifications(); // Tải lại danh sách để cập nhật trạng thái UI
    } catch (e) {
      debugPrint("Lỗi khi đánh dấu đã đọc: $e");
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String fullImageUrl = _userService.apiClient.buildImageUrl(
      _profile?.avatarUrl,
    );
    final double width = MediaQuery.of(context).size.width;
    final bool compactHeader = width < 1200;
    final bool hideSearch = width < 980;
    final bool veryCompact = width < 760;

    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.adminSurface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.adminBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          width: constraints.maxWidth,
          child: Row(
            children: [
              _buildLogoSection(veryCompact),
              const SizedBox(width: 16),
              if (!hideSearch)
                Expanded(
                  child: Center(
                    child: _buildSearchBox(maxWidth: compactHeader ? 240 : 360),
                  ),
                )
              else
                const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildNotificationBell(),
                  const SizedBox(width: 12),
                  _buildProfileSection(
                    fullImageUrl,
                    compactHeader || veryCompact,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBox({required double maxWidth}) {
    return SizedBox(
      width: maxWidth,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.adminBorder),
        ),
        child: TextField(
          controller: _searchController,
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.adminTextPrimary,
          ),
          decoration: const InputDecoration(
            hintText: 'Tìm kiếm mọi thứ...',
            hintStyle: TextStyle(
              color: AppColors.adminTextSecondary,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search,
              size: 20,
              color: AppColors.adminTextSecondary,
            ),
            prefixIconConstraints: BoxConstraints(minWidth: 48, minHeight: 48),

            border: InputBorder.none,
            isCollapsed: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(String fullImageUrl, bool compact) {
    if (_isLoadingProfile) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!compact)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.adminSurfaceMuted,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.adminBorder),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _profile?.fullName ?? "Admin",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.adminTextPrimary,
                    ),
                  ),
                  Text(
                    "Quản trị viên",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        if (!compact) const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.adminBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.adminAccentSoft,
            backgroundImage: (_profile?.avatarUrl != null)
                ? NetworkImage(fullImageUrl)
                : null,
            child: (_profile?.avatarUrl == null)
                ? const Icon(Icons.person, color: AppColors.adminAccentDeep)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildLogoSection(bool compact) {
    return Row(
      children: [
        Container(
          width: compact ? 36 : 42,
          height: compact ? 36 : 42,
          decoration: BoxDecoration(
            gradient: AppColors.adminHeroGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.adminAccent.withOpacity(0.28),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/images/Logo.svg',
              width: compact ? 18 : 20,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'EcoTrack',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.adminTextPrimary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Admin Console',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.adminTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildNotificationBell() {
    return PopupMenuButton<void>(
      offset: const Offset(0, 55),
      elevation: 10,
      // Tùy chỉnh shape cho toàn bộ popup
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      tooltip: "Thông báo",
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.adminSurfaceMuted,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.adminBorder),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.adminTextPrimary,
              size: 22,
            ),
          ),
          if (_unreadCount > 0)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF5EAC24), // Màu xanh thương hiệu
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: Colors.white, width: 2),
                  ),
                ),
                constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
              ),
            ),
        ],
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Container(
            width: 380, // Tăng nhẹ chiều rộng để thoáng hơn
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header của Popup
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Thông báo",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.adminTextPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Logic đánh dấu đọc tất cả ở đây
                      },
                      child: const Text(
                        "Đọc tất cả",
                        style: TextStyle(
                          color: AppColors.adminAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, thickness: 0.5),
                const SizedBox(height: 8),

                // List danh sách
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 450),
                  child: _notifications.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _notifications.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = _notifications[index];
                            return _buildNotificationItem(item);
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

  Widget _buildNotificationItem(NotificationModel item) {
    bool isUnread = !item.isRead;
    final String audienceLabel = _audienceLabel(item.targetType);
    return InkWell(
      onTap: () => _markAsRead(item.id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUnread
              ? AppColors.adminAccentSoft.withOpacity(0.28)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon với hình nền tròn mềm mại
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getColor(item.type).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(item.type),
                size: 20,
                color: _getColor(item.type),
              ),
            ),
            const SizedBox(width: 14),

            // Nội dung văn bản
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                      color: isUnread
                          ? const Color(0xFF2D3142)
                          : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm • dd/MM/yyyy').format(item.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  if (audienceLabel.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5EAC24).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        audienceLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Chấm báo chưa đọc
            if (isUnread)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF5EAC24),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 48,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 12),
          Text(
            "Tuyệt vời! Không có thông báo mới",
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Cập nhật lại màu sắc cho hiện đại (Eco-friendly Palette)
  Color _getColor(NotificationType type) {
    switch (type) {
      case NotificationType.SYSTEM:
        return const Color(0xFFE74C3C); // Đỏ nhẹ cho hệ thống
      case NotificationType.CAMPAIGN:
        return const Color(0xFF2ECC71); // Xanh lá tươi cho chiến dịch
      default:
        return const Color(0xFF3498DB); // Xanh dương cho thông tin khác
    }
  }

  String _audienceLabel(String? targetType) {
    final normalized = (targetType ?? '').trim().toUpperCase();
    switch (normalized) {
      case 'ROLE_USER':
      case 'USER':
        return 'Người dùng';
      case 'ROLE_ENVIRONMENT':
      case 'ENVIRONMENT':
        return 'Đội môi trường';
      case 'ROLE_ALL':
      case 'GLOBAL':
      case 'ALL':
      case '':
        return '';
      default:
        return normalized;
    }
  }

  IconData _getIcon(NotificationType type) {
    if (type == NotificationType.SYSTEM) return Icons.warning_amber_rounded;
    if (type == NotificationType.CAMPAIGN) return Icons.event_available;
    return Icons.notifications;
  }
}
