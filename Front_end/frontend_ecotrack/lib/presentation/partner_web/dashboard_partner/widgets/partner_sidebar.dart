import 'package:flutter/material.dart';

class PartnerSidebar extends StatefulWidget {
  final String selectedMenu;
  final VoidCallback? onLogout;
  final bool isMobile;
  final Function(String)? onMenuSelected;

  const PartnerSidebar({
    super.key,
    required this.selectedMenu,
    this.onLogout,
    this.isMobile = false,
    this.onMenuSelected,
  });

  @override
  State<PartnerSidebar> createState() => _PartnerSidebarState();
}

class _PartnerSidebarState extends State<PartnerSidebar> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    // Mobile luôn hiển thị đầy đủ trong drawer
    if (widget.isMobile) {
      return _buildSidebarContent(260, false);
    }

    // Desktop: có thể collapse
    double sidebarWidth = _isCollapsed ? 80 : 260;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: sidebarWidth,
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
                    border: Border.all(color: Colors.grey.shade300),
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
          const SizedBox(height: 16),

          // MENU
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _MenuItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Bảng Điều Khiển',
                  isSelected: widget.selectedMenu == 'dashboard',
                  isCollapsed: isCollapsed,
                  onTap: () => widget.onMenuSelected?.call('dashboard'),
                ),
                _MenuItem(
                  icon: Icons.card_giftcard_outlined,
                  label: 'Quản Lý Coupon',
                  isSelected: widget.selectedMenu == 'coupon',
                  isCollapsed: isCollapsed,
                  onTap: () => widget.onMenuSelected?.call('coupon'),
                ),
                _MenuItem(
                  icon: Icons.campaign_outlined,
                  label: 'Tài Trợ Chiến Dịch',
                  isSelected: widget.selectedMenu == 'campaign',
                  isCollapsed: isCollapsed,
                  onTap: () => widget.onMenuSelected?.call('campaign'),
                ),
                _MenuItem(
                  icon: Icons.analytics_outlined,
                  label: 'Phân Tích & Báo Cáo',
                  isSelected: widget.selectedMenu == 'analysis',
                  isCollapsed: isCollapsed,
                  onTap: () => widget.onMenuSelected?.call('analysis'),
                ),
                _MenuItem(
                  icon: Icons.settings_outlined,
                  label: 'Cài Đặt Đối Tác',
                  isSelected: widget.selectedMenu == 'settings',
                  isCollapsed: isCollapsed,
                  onTap: () => widget.onMenuSelected?.call('settings'),
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
