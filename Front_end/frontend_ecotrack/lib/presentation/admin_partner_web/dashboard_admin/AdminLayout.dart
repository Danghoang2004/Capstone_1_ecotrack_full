import 'package:flutter/material.dart';

import 'package:frontend_ecotrack/presentation/admin_partner_web/dashboard_admin/AdminMapPage.dart';
import 'package:frontend_ecotrack/presentation/admin_partner_web/dashboard_admin/AdminReportPage.dart';
import 'package:frontend_ecotrack/presentation/admin_web/dashboard_admin/User_management/screens/user_management_screen.dart';
import 'package:frontend_ecotrack/presentation/admin_web/dashboard_admin/widgets/admin_sidebar.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  // Mặc định vào trang users
  String _selectedMenu = 'users';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          AdminSidebar(
            selectedMenu: _selectedMenu,
            onNavigate: (menu) {
              debugPrint(
                "ADMIN CLICK MENU: $menu",
              ); // Xem log này trong Console
              setState(() {
                _selectedMenu = menu;
              });
            },
          ),

          // Nội dung chính
          Expanded(
            // Dùng KeyedSubtree để buộc vẽ lại khi menu đổi
            child: KeyedSubtree(
              key: ValueKey(_selectedMenu),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedMenu) {
      case 'users':
        return const UserManagementScreen();
      case 'reports':
        return const AdminReportPage();
      case 'map':
        return const AdminMapPage();
      default:
        return Center(child: Text("Menu '$_selectedMenu' không tồn tại"));
    }
  }
}
