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

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  String _selectedMenu = 'dashboard';

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
                    child: KeyedSubtree(
                      key: ValueKey(_selectedMenu),
                      child: _buildContent(),
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

  Widget _buildContent() {
    switch (_selectedMenu) {
      case "dashboard":
        return const AdminDashboardDataScreen();
      case "users":
        return const UserManagementScreen();
      case "reports":
        return const AdminReportPage();
      case "map":
        return const AdminMapPage();
      case "campaign":
        return const AdminCampaignPage();
      case "quiz":
        return const AdminQuizPage();
      default:
        return const Center(child: Text("Chức năng đang phát triển"));
    }
  }
}
