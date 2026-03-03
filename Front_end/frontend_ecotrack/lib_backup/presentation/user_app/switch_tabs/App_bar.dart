import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/presentation/user_app/notification/notification_icon_button.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color.fromARGB(255, 197, 242, 175),
      automaticallyImplyLeading: false,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF3D7D3A),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.eco, color: Colors.white, size: 26),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                "EcoTrack",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2F6B2F),
                ),
              ),
              Text(
                "Bảo vệ môi trường",
                style: TextStyle(fontSize: 12, color: Color(0xFF5E8B5A)),
              ),
            ],
          ),
        ],
      ),
      // actions: [
      //   IconButton(
      //     icon: const Icon(
      //       Icons.notifications_none_rounded,
      //       color: Colors.black87,
      //     ),
      //     onPressed: () {},
      //   ),
      //   Padding(
      //     padding: const EdgeInsets.only(right: 16),
      //     child: ClipOval(
      //       child: Image.asset(
      //         'assets/images/avatar.jpg',
      //         height: 32,
      //         width: 32,
      //         fit: BoxFit.cover,
      //       ),
      //     ),
      //   ),
      // ],
      actions: const [
      NotificationIconButton(),
    ],
    );
  }
}
