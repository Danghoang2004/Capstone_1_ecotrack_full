import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/auth_service.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF5EAC24), // Màu xanh EcoTrack
        title: const Text('EcoTrack Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              // Quay về trang đăng nhập Admin
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
            Text(
              "👋 Chào mừng đến với Trang Quản trị EcoTrack",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Bạn đã đăng nhập thành công với quyền Admin.",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 30),
            Text(
              "Bắt đầu xây dựng giao diện quản lý ở đây...",
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
