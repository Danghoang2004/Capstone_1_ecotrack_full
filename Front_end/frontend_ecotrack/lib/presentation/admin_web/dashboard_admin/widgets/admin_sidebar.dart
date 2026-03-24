import 'package:flutter/material.dart';

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
    double sidebarWidth = _isCollapsed ? 80 : 260;

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
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // Khoảng trống phía trên thay cho User Header cũ
          const SizedBox(height: 20),

          // DANH SÁCH MENU
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
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
                _MenuItem(
                  icon: Icons.map_outlined,
                  label: 'Bản Đồ Rác Thải',
                  keyName: 'map',
                  selectedMenu: widget.selectedMenu,
                  isCollapsed: isCollapsed,
                  onTap: widget.onNavigate,
                ),
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
                  icon: Icons.notifications_active_outlined, // Em có thể đổi icon khác nếu muốn
                  label: 'Quản Lý Thông Báo',
                  keyName: 'notifications', // Key này dùng để nhận diện route/tab
                  selectedMenu: widget.selectedMenu,
                  isCollapsed: isCollapsed,
                  onTap: widget.onNavigate,
                ),
              ],
            ),
          ),

          // NÚT ĐĂNG XUẤT
          Padding(
            padding: const EdgeInsets.all(16),
            child: _MenuItemWidget(
              icon: Icons.logout,
              label: 'Đăng xuất',
              isSelected: false,
              isCollapsed: isCollapsed,
              color: Colors.red[400],
              onTap: widget.onLogout ?? () {},
            ),
          ),
        ],
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
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
              ],
            ),
            child: Icon(
              _isCollapsed ? Icons.chevron_right : Icons.chevron_left,
              size: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }
}

// --- CÁC WIDGET HỖ TRỢ MENU (GIỮ NGUYÊN LOGIC CŨ) ---

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
  final VoidCallback onTap;

  const _MenuItemWidget({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isCollapsed,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 50,
        margin: const EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF5EAC24).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: isCollapsed
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Icon(
              icon,
              color:
                  color ??
                  (isSelected ? const Color(0xFF5EAC24) : Colors.grey[600]),
              size: 24,
            ),
            if (!isCollapsed) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color:
                        color ??
                        (isSelected
                            ? const Color(0xFF5EAC24)
                            : Colors.grey[700]),
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
