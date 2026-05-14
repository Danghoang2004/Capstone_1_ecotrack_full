import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/admin_realtime_service.dart';
import 'package:frontend_ecotrack/core/theme/app_colors.dart';
import 'package:frontend_ecotrack/core/services/auth_service.dart';
import 'package:frontend_ecotrack/presentation/admin_partner_web/admin_question/AdminQuizPage.dart';
import 'package:frontend_ecotrack/presentation/admin_partner_web/campaign_manage_admin/AdminCampainPage.dart';

import 'package:frontend_ecotrack/presentation/admin_partner_web/dashboard_admin/AdminDarhboard_data.dart';
import 'package:frontend_ecotrack/presentation/admin_partner_web/dashboard_admin/AdminEnvironmentTaskPage.dart';
import 'package:frontend_ecotrack/presentation/admin_partner_web/dashboard_admin/AdminEnvironmentTeamPage.dart';
import 'package:frontend_ecotrack/presentation/admin_partner_web/dashboard_admin/AdminMapPage.dart';
import 'package:frontend_ecotrack/presentation/admin_partner_web/dashboard_admin/AdminReportPage.dart';
import 'package:frontend_ecotrack/presentation/admin_web/dashboard_admin/environment_user_management/screens/environment_user_management_screen.dart';
import 'package:frontend_ecotrack/presentation/admin_web/dashboard_admin/User_management/screens/user_management_screen.dart';
import 'package:frontend_ecotrack/presentation/admin_web/dashboard_admin/widgets/admin_header.dart';
import 'package:frontend_ecotrack/presentation/admin_web/dashboard_admin/widgets/admin_sidebar.dart';
import 'package:frontend_ecotrack/presentation/admin_app/badge_management/admin_badge_management_screen.dart';
import '../notification_manage_admin/AdminNotificationPage.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  String _selectedMenu = 'dashboard';
  int _globalRefreshVersion = 0;
  int _environmentTasksPageVersion = 0;
  int _environmentTeamsPageVersion = 0;
  late final AdminRealtimeService _adminRealtimeService;
  StreamSubscription<AdminRealtimeEvent>? _realtimeSubscription;

  int _selectedIndex = 0;

  static const Map<String, int> _menuIndex = {
    'dashboard': 0,
    'users': 1,
    'environment_users': 2,
    'reports': 3,
    'environment_tasks': 4,
    'environment_teams': 5,
    'map': 6,
    'campaign': 7,
    'quiz': 8,
    'badges': 9,
    'notifications': 10,
  };

  @override
  void initState() {
    super.initState();
    _adminRealtimeService = AdminRealtimeService.instance;
    _adminRealtimeService.start();
    _realtimeSubscription = _adminRealtimeService.events.listen((event) {
      if (!mounted || !event.isReportEvent) return;

      // Rebuild all admin tabs when report events arrive so screens refetch data immediately.
      setState(() {
        _globalRefreshVersion++;
      });
    });
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _adminRealtimeService.stop();
    super.dispose();
  }

  List<Widget> _buildPages() {
    return [
      AdminDashboardDataScreen(key: ValueKey('dashboard_$_globalRefreshVersion')),
      UserManagementScreen(key: ValueKey('users_$_globalRefreshVersion')),
      EnvironmentUserManagementScreen(
        key: ValueKey('environment_users_$_globalRefreshVersion'),
      ),
      AdminReportPage(key: ValueKey('reports_$_globalRefreshVersion')),
      AdminEnvironmentTaskPage(
        key: ValueKey(
          'environment_tasks_$_globalRefreshVersion$_environmentTasksPageVersion',
        ),
      ),
      AdminEnvironmentTeamPage(
        key: ValueKey(
          'environment_teams_$_globalRefreshVersion$_environmentTeamsPageVersion',
        ),
      ),
      AdminMapPage(key: ValueKey('map_$_globalRefreshVersion')),
      AdminCampaignPage(key: ValueKey('campaign_$_globalRefreshVersion')),
      AdminQuizPage(key: ValueKey('quiz_$_globalRefreshVersion')),
      AdminBadgeManagementScreen(key: ValueKey('badges_$_globalRefreshVersion')),
      AdminNotificationPage(key: ValueKey('notifications_$_globalRefreshVersion')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.adminBackgroundGradient,
              ),
            ),
          ),
          Positioned(
            top: -110,
            right: -90,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.adminAccentSoft.withOpacity(0.45),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.adminAccentSoft.withOpacity(0.32),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const AdminHeader(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.adminSurface,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.adminBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 28,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AdminSidebar(
                              selectedMenu: _selectedMenu,
                              onNavigate: (menu) {
                                setState(() {
                                  _selectedMenu = menu;
                                  _selectedIndex = _menuIndex[menu] ?? 0;

                                  if (menu == 'environment_tasks') {
                                    _environmentTasksPageVersion++;
                                  }
                                  if (menu == 'environment_teams') {
                                    _environmentTeamsPageVersion++;
                                  }
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
                                color: AppColors.adminSurfaceSoft,
                                child: IndexedStack(
                                  index: _selectedIndex,
                                  children: _buildPages(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
