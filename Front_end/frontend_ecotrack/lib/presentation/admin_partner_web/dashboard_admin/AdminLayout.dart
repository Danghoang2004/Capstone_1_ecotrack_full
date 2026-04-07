import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/auth_service.dart';
import 'package:frontend_ecotrack/presentation/admin_partner_web/admin_question/AdminQuizPage.dart';
import 'package:frontend_ecotrack/presentation/admin_partner_web/campaign_manage_admin/AdminCampainPage.dart';

import 'package:frontend_ecotrack/presentation/admin_partner_web/dashboard_admin/AdminDarhboard_data.dart';
import 'package:frontend_ecotrack/presentation/admin_partner_web/dashboard_admin/AdminMapPage.dart';
import 'package:frontend_ecotrack/presentation/admin_partner_web/dashboard_admin/AdminReportPage.dart';
import 'package:frontend_ecotrack/presentation/admin_web/dashboard_admin/User_management/screens/user_management_screen.dart';
import 'package:frontend_ecotrack/presentation/admin_web/dashboard_admin/widgets/admin_header.dart';
import 'package:frontend_ecotrack/presentation/admin_web/dashboard_admin/widgets/admin_sidebar.dart';
import '../notification_manage_admin/AdminNotificationPage.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  String _selectedMenu = 'dashboard';
  late final List<String> _menuOrder;
  late final List<Widget> _pages;

  int _selectedIndex = 0;

  static const Map<String, int> _menuIndex = {
    'dashboard': 0,
    'users': 1,
    'reports': 2,
    'map': 3,
    'campaign': 4,
    'quiz': 5,
    'notifications': 6,
  };

  @override
  void initState() {
    super.initState();
    _menuOrder = const [
      'dashboard',
      'users',
      'reports',
      'map',
      'campaign',
      'quiz',
      'notifications',
    ];
    _pages = const [
      AdminDashboardDataScreen(),
      UserManagementScreen(),
      AdminReportPage(),
      AdminMapPage(),
      AdminCampaignPage(),
      AdminQuizPage(),
      AdminNotificationPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const AdminHeader(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // A. SIDEBAR (BÊN TRÁI)
                AdminSidebar(
                  selectedMenu: _selectedMenu,
                  onNavigate: (menu) {
                    setState(() {
                      _selectedMenu = menu;
                      _selectedIndex = _menuIndex[menu] ?? 0;
                    });
                  },
                  onLogout: () async {
                    final authService = AuthService();
                    await authService.logout();
                    if (mounted) {
                      Navigator.of(
                        context,
                      ).pushReplacementNamed('/admin_login');
                    }
                  },
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: const Color(0xFFF5F7FA),
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: _pages,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
