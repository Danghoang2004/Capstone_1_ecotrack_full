import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/profile_controller.dart';

class HeaderWidget extends StatelessWidget {
  final ProfileController controller;

  const HeaderWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(color: HomeColors.bgHeader),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Row(
            children: [
              // Logo rỗng (chưa có hình) - không hiển thị
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EcoTrack',
                    style: TextStyle(
                      color: AppColors.textLogo,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'Bảo vệ môi trường',
                    style: TextStyle(color: AppColors.black, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          // Notification và avatar
          Row(
            children: [
              Stack(
                children: [
                  const Icon(
                    Icons.notifications,
                    size: 24,
                    color: AppColors.black,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey,
                backgroundImage: NetworkImage(controller.imageUrl),
                onBackgroundImageError: (exception, stackTrace) {
                  // Nếu load ảnh lỗi thì hiển thị icon mặc định
                },
                child: controller.imageUrl.isEmpty
                    ? const Icon(Icons.person, color: AppColors.white, size: 20)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
