import 'package:flutter/material.dart';
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

  // Static method để switch sang ranking screen từ bên ngoài
  static void switchToRanking(BuildContext? context) {
    if (context != null) {
      // Tìm Userlayout trong widget tree (tìm cả StatefulWidget và State)
      final userLayout = context.findAncestorWidgetOfExactType<Userlayout>();
      if (userLayout != null) {
        final state = context.findAncestorStateOfType<_UserlayoutState>();
        if (state != null) {
          state.switchToRanking();
          return;
        }
      }
      // Fallback: push route mới (chỉ cho mobile)
      final screenWidth = MediaQuery.of(context).size.width;
      if (screenWidth <= 800) {
        Navigator.pushNamed(context, '/ranking');
      }
    }
  }
}

class _UserlayoutState extends State<Userlayout> with WidgetsBindingObserver {
  int currentIndex = 0;
  bool _isCollapsed = false;
  final HomeController homeController = HomeController();

  late final List<Widget> screens;
  final List<_NavItem> navItems = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.map, label: 'Map'),
    _NavItem(icon: Icons.person_rounded, label: 'Profile'),
    _NavItem(icon: Icons.settings, label: 'Setting'),
  ];

  @override
  void initState() {
    super.initState();
    // Pass showWelcomeDialog to HomeScreen
    // Desktop: hide AppBar cho các screen khác
    screens = [
      HomeScreen(showWelcomeDialog: widget.showWelcomeDialog),
      MapPage(hideAppBar: false), // Mobile: hiển thị AppBar
      ProfileScreen(),
      SettingsScreen(),
      const RankingScreen(hideHeader: false), // Ranking screen
    ];
    WidgetsBinding.instance.addObserver(this);
    // Check session ngay khi vào màn hình
    SessionCheckerService.checkNow();
    // Bắt đầu check session định kỳ khi vào app (mỗi 3 giây để test nhanh hơn)
    SessionCheckerService.startChecking(interval: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Dừng check session khi rời khỏi app
    SessionCheckerService.stopChecking();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Khi app resume, check session ngay và tiếp tục check định kỳ
      SessionCheckerService.checkNow();
      SessionCheckerService.startChecking(interval: const Duration(seconds: 5));
    } else if (state == AppLifecycleState.paused) {
      // Khi app pause, dừng check để tiết kiệm tài nguyên
      SessionCheckerService.stopChecking();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800; // Desktop breakpoint

    if (isDesktop) {
      // Desktop: Header full width (luôn hiển thị header của Home), Sidebar bên trái ở phần content
      return Scaffold(
        body: Column(
          children: [
            // Header full width (luôn hiển thị header của Home cho tất cả screen)
            HeaderWidget(
              controller: homeController.profileController,
              onAvatarTap: () {
                // Switch tới Profile tab (index 2)
                setState(() {
                  currentIndex = 2;
                });
              },
            ),
            // Content với sidebar bên trái
            Expanded(
              child: Row(
                children: [
                  _buildDesktopSidebar(),
                  Expanded(
                    child: currentIndex == 0
                        ? HomeScreen(
                            showWelcomeDialog: widget.showWelcomeDialog,
                            hideHeader: true,
                          )
                        : _getDesktopScreen(currentIndex),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Mobile: Bottom navigation bar (giữ nguyên)
      return Scaffold(
        body: screens[currentIndex],
        bottomNavigationBar: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (value) {
              setState(() {
                currentIndex = value;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color.fromARGB(255, 160, 231, 124),
            elevation: 12,
            selectedItemColor: const Color.fromARGB(255, 2, 85, 2),
            unselectedItemColor: Colors.grey,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            iconSize: 22,
            items: [
              const BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Icon(Icons.home_rounded),
                ),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Icon(Icons.map),
                ),
                label: 'Map',
              ),
              const BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Icon(Icons.person_rounded),
                ),
                label: 'Profile',
              ),
              const BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Icon(Icons.settings),
                ),
                label: 'Setting',
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildDesktopSidebar() {
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
          // Nút collapse
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
          // MENU ITEMS
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: navItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _MenuItem(
                  icon: item.icon,
                  label: item.label,
                  isSelected: currentIndex == index,
                  isCollapsed: isCollapsed,
                  onTap: () {
                    setState(() {
                      currentIndex = index;
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Get screen cho desktop mode (ẩn AppBar)
  Widget _getDesktopScreen(int index) {
    switch (index) {
      case 1: // Map
        return MapPage(hideAppBar: true);
      case 2: // Profile
        return ProfileScreen(hideAppBar: true);
      case 3: // Setting
        return SettingsScreen(hideAppBar: true);
      case 4: // Ranking
        return const RankingScreen(hideHeader: true);
      default:
        return HomeScreen(
          showWelcomeDialog: widget.showWelcomeDialog,
          hideHeader: true,
        );
    }
  }

  // Method để switch sang ranking screen từ bên ngoài
  void switchToRanking() {
    setState(() {
      currentIndex = 4;
    });
  }
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
