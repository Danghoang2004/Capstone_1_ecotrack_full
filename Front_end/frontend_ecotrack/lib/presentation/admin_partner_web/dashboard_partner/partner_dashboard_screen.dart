import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/auth_service.dart';

class PartnerDashboardScreen extends StatelessWidget {
  const PartnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5), // Màu xanh dương cho Partner
        title: const Text('EcoTrack Partner Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              // Quay về trang đăng nhập chung
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/admin_login',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_center, size: 80, color: Color(0xFF1E88E5)),
            SizedBox(height: 20),
            Text(
              "Chào mừng Partner!",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Đây là trang quản lý dữ liệu bạn cung cấp.",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 30),
            Text(
              "Hãy bắt đầu xây dựng các biểu đồ và form quản lý...",
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
