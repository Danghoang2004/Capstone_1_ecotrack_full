import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/presentation/user_app/classification/waste_ai_classification_page.dart';
import 'package:frontend_ecotrack/presentation/user_app/home/screens/home_screen.dart';
import 'package:frontend_ecotrack/presentation/user_app/Map/Map_page.dart';
import 'package:frontend_ecotrack/presentation/user_app/Setting/Setting_page.dart';
import 'package:frontend_ecotrack/presentation/user_app/profile/ProfileScreen.dart';
import 'package:frontend_ecotrack/presentation/user_app/ranking/screens/ranking_screen.dart';
import 'package:frontend_ecotrack/core/services/session_checker_service.dart';
import 'package:frontend_ecotrack/presentation/user_app/home/widgets/header/header.dart';
import 'package:frontend_ecotrack/presentation/user_app/home/controllers/home_controller.dart';

class Userlayout extends StatefulWidget {
  final bool showWelcomeDialog;
  const Userlayout({super.key, this.showWelcomeDialog = false});

  @override
  State<Userlayout> createState() => _UserlayoutState();

  static void switchToRanking(BuildContext? context) {
    if (context != null) {
      final state = context.findAncestorStateOfType<_UserlayoutState>();
      if (state != null) {
        state.switchToRanking();
        return;
      }
      final screenWidth = MediaQuery.of(context).size.width;
      if (screenWidth <= 800) {
        Navigator.pushNamed(context, '/ranking');
      }
    }
  }
}

// --- PHẦN VẼ THANH NAVBAR (CUSTOM PAINTER) ---
class BottomNotchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    Path path = Path();
    double holeRadius = 30;
    double curveRadius = 1;

    // --- CHỈNH ĐỘ BO GÓC TẠI ĐÂY (Số càng nhỏ thì góc càng ít bo) ---
    double radius = 20.0;

    // Bắt đầu tại điểm sau khi bo góc trái trên
    path.moveTo(radius, 0);
    path.lineTo(size.width / 2 - holeRadius - curveRadius, 0);

    // Vẽ lỗ khoét ở giữa (Giữ nguyên logic của bạn)
    path.quadraticBezierTo(
      size.width / 2 - holeRadius,
      0,
      size.width / 2 - holeRadius,
      curveRadius,
    );
    path.arcToPoint(
      Offset(size.width / 2 + holeRadius, curveRadius),
      radius: Radius.circular(holeRadius),
      clockwise: false,
    );
    path.quadraticBezierTo(
      size.width / 2 + holeRadius,
      0,
      size.width / 2 + holeRadius + curveRadius,
      0,
    );

    // 1. Đi đến góc Phải Trên và bo góc
    path.lineTo(size.width - radius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, radius);

    // 2. Đi xuống góc Phải Dưới và bo góc
    path.lineTo(size.width, size.height - radius);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - radius,
      size.height,
    );

    // 3. Đi sang góc Trái Dưới và bo góc
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);

    // 4. Đi lên góc Trái Trên và bo góc cuối cùng
    path.lineTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);

    canvas.drawShadow(path, Colors.black.withOpacity(0.5), 10, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// --- PHẦN STATE CHÍNH ---
class _UserlayoutState extends State<Userlayout> with WidgetsBindingObserver {
  int currentIndex = 0;
  bool _isCollapsed = false;
  final HomeController homeController = HomeController();

  late final List<Widget> screens;
  final List<_NavItem> navItems = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.map, label: 'Map'),
    _NavItem(icon: Icons.list, label: 'List_Report'),
    _NavItem(icon: Icons.person_rounded, label: 'Profile'),
    _NavItem(icon: Icons.settings, label: 'Setting'),
  ];

  @override
  void initState() {
    super.initState();
    screens = [
      HomeScreen(showWelcomeDialog: widget.showWelcomeDialog),
      MapPage(hideAppBar: false),
      WasteAiClassificationPage(),
      ProfileScreen(hideAppBar: false),
      SettingsScreen(),
      const RankingScreen(hideHeader: false),
    ];
    WidgetsBinding.instance.addObserver(this);
    SessionCheckerService.checkNow();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SessionCheckerService.checkNow();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Widget _navItem(IconData icon, int index) {
    bool isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive
                ? const Color(0xFF2E7D32)
                : Colors.grey.withOpacity(0.6),
            size: 20,
          ),
          const SizedBox(height: 0),
          if (isActive)
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: isDesktop
          ? Column(
              children: [
                HeaderWidget(
                  controller: homeController.profileController,
                  onAvatarTap: () => setState(() => currentIndex = 1),
                ),
                Expanded(
                  child: Row(
                    children: [
                      _buildDesktopSidebar(),
                      Expanded(child: _getDesktopScreen(currentIndex)),
                    ],
                  ),
                ),
              ],
            )
          : screens[currentIndex],
      bottomNavigationBar: isDesktop ? null : _buildFloatingNavBar(),
    );
  }

  Widget _buildFloatingNavBar() {
    return Container(
      margin: const EdgeInsets.only(left: 3, right: 3, bottom: 3),
      height: 70,
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CustomPaint(
            size: const Size(double.infinity, 45),
            painter: BottomNotchPainter(),
          ),
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.home_rounded, 0),
                _navItem(Icons.map_outlined, 1),
                const SizedBox(width: 45),
                _navItem(Icons.person_outline, 3),
                _navItem(Icons.settings_outlined, 4),
              ],
            ),
          ),
          Positioned(
            top: 6,
            child: GestureDetector(
              onTap: () => setState(() => currentIndex = 2),
              child: Container(
                height: 50,
                width: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.eco, color: Colors.white, size: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    double sidebarWidth = _isCollapsed ? 80 : 260;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: sidebarWidth + 12,
      child: Stack(
        children: [
          _buildSidebarContent(sidebarWidth, _isCollapsed),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: InkWell(
                onTap: () => setState(() => _isCollapsed = !_isCollapsed),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Icon(
                    _isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                    size: 1,
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
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          const SizedBox(height: 16),
          ...navItems.asMap().entries.map(
            (entry) => _MenuItem(
              icon: entry.value.icon,
              label: entry.value.label,
              isSelected: currentIndex == entry.key,
              isCollapsed: isCollapsed,
              onTap: () => setState(() => currentIndex = entry.key),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getDesktopScreen(int index) {
    switch (index) {
      case 1:
        return MapPage(hideAppBar: true);
      case 2:
        return WasteAiClassificationPage();
      case 3:
        return ProfileScreen(hideAppBar: true);
      case 4:
        return SettingsScreen(hideAppBar: true);
      default:
        return HomeScreen(
          showWelcomeDialog: widget.showWelcomeDialog,
          hideHeader: true,
        );
    }
  }

  void switchToRanking() => setState(() => currentIndex = 5);
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem({required this.icon, required this.label});
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isCollapsed,
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
              ? const Color(0xFF5EAC24).withOpacity(0.2)
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
              color: isSelected
                  ? const Color(0xFF5EAC24)
                  : const Color(0xFF1A1A1A),
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
                    color: isSelected
                        ? const Color(0xFF5EAC24)
                        : const Color(0xFF1A1A1A),
                  ),
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
