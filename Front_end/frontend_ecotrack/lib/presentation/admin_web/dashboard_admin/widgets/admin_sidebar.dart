import 'package:flutter/material.dart';

class AdminSidebar extends StatefulWidget {
  final String selectedMenu;
  final VoidCallback? onLogout;
  final bool isMobile;
  final Function(String)? onNavigate;
  const AdminSidebar({
    super.key,
    required this.selectedMenu,
    this.onLogout,
    this.isMobile = false,
    this.onNavigate,
  });

  @override
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    // Mobile luôn hiển thị đầy đủ trong drawer
    if (widget.isMobile) {
      return _buildSidebarContent(260, false);
    }

    // Desktop: có thể collapse
    double sidebarWidth = _isCollapsed ? 80 : 260;
    double totalWidth = sidebarWidth + 12;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: totalWidth,
      height: double.infinity,
      color: Colors.transparent,
      child: Stack(
        children: [
          _buildSidebarContent(sidebarWidth, _isCollapsed),

          // Nút collapse (chỉ cho desktop)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isCollapsed = !_isCollapsed;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color.fromARGB(255, 255, 255, 255),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
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
          ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // HEADER
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5EAC24),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(Icons.eco, color: Colors.white, size: 24),
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'EcoTrack System',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),
          const SizedBox(height: 16),

          // MENU
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _MenuItem(
                  icon: Icons.people_outline,
                  label: 'Quản lý người dùng',
                  isSelected: widget.selectedMenu == 'users', // Logic chọn menu
                  isCollapsed: isCollapsed,
                  onTap: () => widget.onNavigate?.call(
                    'users',
                  ), // Gọi callback chuyển trang
                ),
                _MenuItem(
                  icon: Icons.assignment_outlined, // Icon báo cáo
                  label: 'Quản lý báo cáo',
                  isSelected: widget.selectedMenu == 'reports',
                  isCollapsed: isCollapsed,
                  onTap: () => widget.onNavigate?.call('reports'),
                ),
                _MenuItem(
                  icon: Icons.map_outlined, // Icon bản đồ
                  label: 'Bản đồ rác thải',
                  isSelected: widget.selectedMenu == 'map',
                  isCollapsed: isCollapsed,
                  onTap: () => widget.onNavigate?.call('map'),
                ),
              ],
            ),
          ),

          // LOGOUT
          Padding(
            padding: const EdgeInsets.all(16),
            child: _MenuItem(
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
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isCollapsed;
  final Color? color;
  final VoidCallback onTap;

  const _MenuItem({
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
              ? const Color(0xFF5EAC24).withOpacity(0.1)
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
