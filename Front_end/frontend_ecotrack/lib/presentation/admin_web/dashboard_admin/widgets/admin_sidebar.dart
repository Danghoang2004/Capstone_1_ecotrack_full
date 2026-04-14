import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/theme/app_colors.dart';

class AdminSidebar extends StatefulWidget {
  final String selectedMenu;
  final Function(String)? onNavigate;
  final VoidCallback? onLogout;

  const AdminSidebar({
    super.key,
    required this.selectedMenu,
    this.onNavigate,
    this.onLogout,
  });

  @override
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final double sidebarWidth = _isCollapsed ? 88 : 286;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: sidebarWidth,
      height: double.infinity,
      child: Stack(
        children: [
          _buildSidebarContent(sidebarWidth, _isCollapsed),
          _buildCollapseButton(),
        ],
      ),
    );
  }

  Widget _buildSidebarContent(double width, bool isCollapsed) {
    return Container(
      width: width,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.adminSidebarGradient,
      ),
      child: Column(
        children: [
          _buildBrandPanel(isCollapsed),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: isCollapsed ? 10 : 14,
                vertical: 10,
              ),
              children: [
                _buildSectionLabel('Tổng quan', isCollapsed),
                _MenuItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Bảng Điều Khiển',
                  keyName: 'dashboard',
                  selectedMenu: widget.selectedMenu,
                  isCollapsed: isCollapsed,
                  onTap: widget.onNavigate,
                ),
                _MenuItem(
                  icon: Icons.people_outline,
                  label: 'Quản Lý Người Dùng',
                  keyName: 'users',
                  selectedMenu: widget.selectedMenu,
                  isCollapsed: isCollapsed,
                  onTap: widget.onNavigate,
                ),
                _MenuItem(
                  icon: Icons.assignment_outlined,
                  label: 'Quản Lý Báo Cáo',
                  keyName: 'reports',
                  selectedMenu: widget.selectedMenu,
                  isCollapsed: isCollapsed,
                  onTap: widget.onNavigate,
                ),
                const SizedBox(height: 8),
                _buildSectionLabel('Vận hành', isCollapsed),
                _MenuItem(
                  icon: Icons.groups_outlined,
                  label: 'Phân Công Môi Trường',
                  keyName: 'environment_tasks',
                  selectedMenu: widget.selectedMenu,
                  isCollapsed: isCollapsed,
                  onTap: widget.onNavigate,
                ),
                _MenuItem(
                  icon: Icons.diversity_3_outlined,
                  label: 'Đội & KPI',
                  keyName: 'environment_teams',
                  selectedMenu: widget.selectedMenu,
                  isCollapsed: isCollapsed,
                  onTap: widget.onNavigate,
                ),
                _MenuItem(
                  icon: Icons.map_outlined,
                  label: 'Bản Đồ Rác Thải',
                  keyName: 'map',
                  selectedMenu: widget.selectedMenu,
                  isCollapsed: isCollapsed,
                  onTap: widget.onNavigate,
                ),
                const SizedBox(height: 8),
                _buildSectionLabel('Nội dung', isCollapsed),
                _MenuItem(
                  icon: Icons.campaign_outlined,
                  label: 'Quản Lý Chiến Dịch',
                  keyName: 'campaign',
                  selectedMenu: widget.selectedMenu,
                  isCollapsed: isCollapsed,
                  onTap: widget.onNavigate,
                ),
                _MenuItem(
                  icon: Icons.question_answer_outlined,
                  label: 'Quản Lý Câu Hỏi',
                  keyName: 'quiz',
                  selectedMenu: widget.selectedMenu,
                  isCollapsed: isCollapsed,
                  onTap: widget.onNavigate,
                ),
                _MenuItem(
                  icon: Icons.notifications_active_outlined,
                  label: 'Quản Lý Thông Báo',
                  keyName: 'notifications',
                  selectedMenu: widget.selectedMenu,
                  isCollapsed: isCollapsed,
                  onTap: widget.onNavigate,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            child: _MenuItemWidget(
              icon: Icons.logout,
              label: 'Đăng xuất',
              isSelected: false,
              isCollapsed: isCollapsed,
              color: Colors.red[100],
              labelColor: Colors.red[50],
              backgroundColor: Colors.white.withOpacity(0.08),
              onTap: widget.onLogout ?? () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandPanel(bool isCollapsed) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isCollapsed ? 12 : 16,
        vertical: isCollapsed ? 18 : 22,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A4636), Color(0xFF16372A)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isCollapsed
          ? const Column(
              children: [
                _BrandIcon(size: 44),
              ],
            )
          : Row(
              children: const [
                _BrandIcon(size: 46),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'EcoTrack Admin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Bảng điều khiển quản trị',
                        style: TextStyle(
                          color: Color(0xFFD9E7DC),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionLabel(String label, bool isCollapsed) {
    if (isCollapsed) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withOpacity(0.56),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
        ),
      ),
    );
  }

  Widget _buildCollapseButton() {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: Center(
        child: InkWell(
          onTap: () => setState(() => _isCollapsed = !_isCollapsed),
          child: Container(
            width: 30,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(999),
              ),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              _isCollapsed ? Icons.chevron_right : Icons.chevron_left,
              size: 18,
              color: AppColors.adminAccentDeep,
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandIcon extends StatelessWidget {
  final double size;

  const _BrandIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: const Icon(
        Icons.recycling_outlined,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String keyName;
  final String selectedMenu;
  final bool isCollapsed;
  final Function(String)? onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.keyName,
    required this.selectedMenu,
    required this.isCollapsed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _MenuItemWidget(
      icon: icon,
      label: label,
      isSelected: selectedMenu == keyName,
      isCollapsed: isCollapsed,
      onTap: () => onTap?.call(keyName),
    );
  }
}

class _MenuItemWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isCollapsed;
  final Color? color;
  final Color? labelColor;
  final Color? backgroundColor;
  final VoidCallback onTap;

  const _MenuItemWidget({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isCollapsed,
    this.color,
    this.labelColor,
    this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        height: 46,
        margin: const EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 14),
        decoration: BoxDecoration(
          color: isSelected ? null : backgroundColor ?? Colors.transparent,
          gradient: isSelected ? AppColors.adminMenuSelectedGradient : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.white.withOpacity(0.34)
                : Colors.transparent,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.adminAccentSky.withOpacity(0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: isCollapsed
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.22)
                    : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color ?? (isSelected ? Colors.white : Colors.white70),
                size: 20,
              ),
            ),
            if (!isCollapsed) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: labelColor ?? (isSelected ? Colors.white : Colors.white70),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
