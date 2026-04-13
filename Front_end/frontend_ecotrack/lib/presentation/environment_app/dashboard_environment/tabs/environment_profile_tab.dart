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
                    _buildAvatar(size: 72),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFB7F34D),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hồ sơ tài khoản',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        roleLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MiniBadge(
                            icon: Icons.verified_user_outlined,
                            text: 'Đang hoạt động',
                            background: Colors.white.withOpacity(0.16),
                            foreground: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8EFE5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thông tin đội nhóm',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2D1D),
                  ),
                ),
                const SizedBox(height: 12),
                if (myTeamInfo == null)
                  const Text(
                    'Bạn chưa thuộc đội môi trường nào.',
                    style: TextStyle(color: Color(0xFF64748B)),
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8EFE5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thông tin tài khoản',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2D1D),
                  ),
                ),
                const SizedBox(height: 12),
                EnvironmentProfileRow(
                  icon: Icons.badge_outlined,
                  label: 'Chức năng',
                  value: 'Đội xử lý môi trường',
                ),
                const SizedBox(height: 8),
                EnvironmentProfileRow(
                  icon: Icons.verified_user_outlined,
                  label: 'Quyền',
                  value: 'Nhận việc và báo cáo hoàn tất',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7F3),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8DD)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF5EAC24)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Màn hình tài khoản được tối ưu cho thao tác nhanh, rõ vai trò và trạng thái hiện tại.',
                    style: TextStyle(color: Color(0xFF49604A), height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
                  : const Icon(Icons.logout),
              label: const Text('Đăng xuất'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
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

class _MiniBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color background;
  final Color foreground;

  const _MiniBadge({
    required this.icon,
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
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
        border: Border.all(color: const Color(0xFFE8EFE5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF1F2D1D),
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
