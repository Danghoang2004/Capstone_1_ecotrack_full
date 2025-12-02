import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/presentation/user_app/notification/notification_screen.dart';

/// Nút chuông dùng trong AppBar
/// Bấm vào sẽ mở NotificationScreen
class NotificationIconButton extends StatelessWidget {
  const NotificationIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.notifications_none_rounded,
        color: Colors.black87,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const NotificationScreen(),
          ),
        );
      },
    );
  }
}
