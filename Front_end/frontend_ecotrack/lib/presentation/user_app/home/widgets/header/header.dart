import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../controllers/profile_controller.dart';

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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: HomeColors
                      .logoBorderColor, // Background màu xanh lá cây đậm
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/Logo.svg',
                    width: 30,
                    height: 30,
                    colorFilter: const ColorFilter.mode(
                      AppColors.white,
                      BlendMode.srcIn,
                    ), // Màu trắng cho logo
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
              SizedBox(
                width: 36,
                height: 36,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      bottom: 6,
                      child: SvgPicture.asset(
                        'assets/icons/notifications.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          AppColors.black,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            '5',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
