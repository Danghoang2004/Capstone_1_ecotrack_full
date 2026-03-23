import 'package:flutter/material.dart';
import 'create_notification_screen.dart'; // Import file em vừa tạo ở trên

class AdminNotificationPage extends StatelessWidget {
  const AdminNotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Quản Lý Thông Báo",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  "Tạo thông báo mới",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5EAC24), // Xanh EcoTrack
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                onPressed: () {
                  // Chuyển hướng sang màn hình Tạo Thông Báo
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateNotificationScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const Expanded(
            child: Center(
              child: Text(
                "Chưa có thông báo nào. Bấm 'Tạo thông báo mới' để bắt đầu.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
