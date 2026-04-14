import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/data/models/environment_my_team_info_model.dart';
import 'package:frontend_ecotrack/presentation/environment_app/dashboard_environment/widgets/environment_profile_row.dart';

class EnvironmentProfileTab extends StatelessWidget {
  final String userName;
  final String userRole;
  final String avatarImageUrl;
  final EnvironmentMyTeamInfo? myTeamInfo;
  final VoidCallback onLogout;
  final bool isLoggingOut;

  const EnvironmentProfileTab({
    super.key,
    required this.userName,
    required this.userRole,
    required this.avatarImageUrl,
    required this.myTeamInfo,
    required this.onLogout,
    required this.isLoggingOut,
  });

  String _roleTitle(String role) {
    switch (role) {
      case 'ROLE_ENVIRONMENT':
        return 'Nhân sự môi trường';
      case 'ROLE_TEAM_LEAD':
        return 'Đội trưởng';
      case 'ROLE_ADMIN':
        return 'Quản trị viên';
      default:
        return role;
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'E';
    if (parts.length == 1) {
      return parts.first.isEmpty ? 'E' : parts.first[0].toUpperCase();
    }
    final first = parts.first.isEmpty ? 'E' : parts.first[0].toUpperCase();
    final last = parts.last.isEmpty ? 'T' : parts.last[0].toUpperCase();
    return '$first$last';
  }

  String _teamRoleTitle(String role) {
    switch (role) {
      case 'LEAD':
        return 'Đội trưởng';
      case 'MEMBER':
        return 'Thành viên';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleLabel = _roleTitle(userRole);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF4F7F3), Color(0xFFF9FBF8)],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Header Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF5EAC24), Color(0xFF2F6F3E)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2F6F3E).withOpacity(0.18),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    _buildAvatar(size: 70),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: const Color(0xFFB7F34D),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hồ sơ của bạn',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        roleLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Đang hoạt động',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.badge_outlined,
                  label: 'Vai trò',
                  value: roleLabel,
                  iconColor: const Color(0xFF2F6F3E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.verified_outlined,
                  label: 'Trạng thái',
                  value: 'Sẵn sàng',
                  iconColor: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Team Info Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8EFE5), width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5EAC24).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.groups_outlined,
                        color: Color(0xFF5EAC24),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Thông tin đội nhóm',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2D1D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (myTeamInfo == null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Bạn chưa thuộc đội môi trường nào.',
                      style: TextStyle(color: Color(0xFF999999), fontSize: 13),
                    ),
                  )
                else ...[
                  EnvironmentProfileRow(
                    icon: Icons.groups_outlined,
                    label: 'Tên đội',
                    value: myTeamInfo!.teamName,
                  ),
                  const SizedBox(height: 8),
                  EnvironmentProfileRow(
                    icon: Icons.badge_outlined,
                    label: 'Vai trò trong đội',
                    value: _teamRoleTitle(myTeamInfo!.myRoleInTeam),
                  ),
                  const SizedBox(height: 8),
                  EnvironmentProfileRow(
                    icon: Icons.person_pin_circle_outlined,
                    label: 'Team lead',
                    value: myTeamInfo!.leadFullName,
                  ),
                  const SizedBox(height: 8),
                  EnvironmentProfileRow(
                    icon: Icons.group_outlined,
                    label: 'Số thành viên',
                    value: '${myTeamInfo!.memberCount} người',
                  ),
                  if (myTeamInfo!.teamDescription.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    EnvironmentProfileRow(
                      icon: Icons.notes_outlined,
                      label: 'Mô tả đội',
                      value: myTeamInfo!.teamDescription,
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Account Info Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8EFE5), width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5EAC24).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.verified_user_outlined,
                        color: Color(0xFF5EAC24),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Thông tin tài khoản',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2D1D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                EnvironmentProfileRow(
                  icon: Icons.badge_outlined,
                  label: 'Chức năng',
                  value: 'Đội xử lý môi trường',
                ),
                const SizedBox(height: 8),
                EnvironmentProfileRow(
                  icon: Icons.verified_user_outlined,
                  label: 'Quyền',
                  value: 'Nhận việc và báo cáo',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Info Banner
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5E4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD7E7D1), width: 0.5),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF5EAC24), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tối ưu hóa cho thao tác nhanh và quản lý dễ dàng.',
                    style: TextStyle(
                      color: Color(0xFF49604A),
                      height: 1.4,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoggingOut ? null : onLogout,
              icon: isLoggingOut
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.logout, size: 18),
              label: Text(
                isLoggingOut ? 'Đang xử lý...' : 'Đăng xuất',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAvatar({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD7E7D1), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: avatarImageUrl.isNotEmpty
            ? Image.network(
                avatarImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _avatarFallback(),
              )
            : _avatarFallback(),
      ),
    );
  }

  Widget _avatarFallback() {
    return Container(
      color: const Color(0xFFEAF5E4),
      alignment: Alignment.center,
      child: Text(
        _initials(userName),
        style: const TextStyle(
          color: Color(0xFF2F6F3E),
          fontWeight: FontWeight.w800,
          fontSize: 24,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EFE5), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF1F2D1D),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
