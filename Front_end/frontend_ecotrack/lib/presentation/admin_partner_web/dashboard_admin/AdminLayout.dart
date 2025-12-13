import 'package:flutter/material.dart';

// --- IMPORT CÁC WIDGET CỦA BẠN ---
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
      // SỬ DỤNG COLUMN ĐỂ HEADER NẰM TRÊN CÙNG
      body: Column(
        children: [
          // -----------------------------------------------------------
          // 1. HEADER (NẰM TRÊN CÙNG - FULL WIDTH)
          // -----------------------------------------------------------
          const AdminHeader(),

          // -----------------------------------------------------------
          // 2. BODY (SIDEBAR + CONTENT)
          // Dùng Expanded để phần này chiếm toàn bộ chiều cao còn lại
          // -----------------------------------------------------------
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
                  onLogout: () {
                    print("Logout clicked");
                  },
                ),

                // B. CONTENT (BÊN PHẢI - GIÃN NỞ)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    height: double
                        .infinity, // Đảm bảo full chiều cao khớp với sidebar
                    color: const Color(0xFFF5F7FA), // Màu nền nội dung
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
      default:
        return const Center(child: Text("Chức năng đang phát triển"));
    }
  }
}
