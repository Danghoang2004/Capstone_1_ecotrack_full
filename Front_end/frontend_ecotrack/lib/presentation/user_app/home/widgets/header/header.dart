import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../controllers/profile_controller.dart';

class HeaderWidget extends StatefulWidget {
  final ProfileController controller;
  final VoidCallback? onAvatarTap; // Callback để switch tab trong UserLayout

  const HeaderWidget({
    super.key,
    required this.controller,
    this.onAvatarTap,
  });

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  @override
  void initState() {
    super.initState();
    // Load profile và rebuild khi xong
    widget.controller.loadProfile().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

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
              _buildAvatar(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final imageUrl = widget.controller.imageUrl;
    final hasValidUrl =
        imageUrl.isNotEmpty &&
        imageUrl !=
            'https://hoanghamobile.com/tin-tuc/wp-content/uploads/2024/11/tai-hinh-nen-dep-mien-phi.jpg' &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));

    Widget avatarWidget;
    if (!hasValidUrl) {
      avatarWidget = CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey[400],
        child: const Icon(Icons.person, color: AppColors.white, size: 20),
      );
    } else {
      avatarWidget = CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey[300],
        backgroundImage: NetworkImage(imageUrl),
        onBackgroundImageError: (exception, stackTrace) {
          // Nếu load ảnh lỗi thì hiển thị icon mặc định
          if (mounted) {
            setState(() {});
          }
        },
        child: widget.controller.isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : null,
      );
    }

    // Wrap avatar trong InkWell để có thể click
    return InkWell(
      onTap: () {
        // Nếu có callback từ UserLayout (desktop mode), dùng callback để switch tab
        // Nếu không, dùng Navigator.pushNamed (mobile mode hoặc standalone)
        if (widget.onAvatarTap != null) {
          widget.onAvatarTap!();
        } else {
          Navigator.pushNamed(context, '/profile');
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: avatarWidget,
    );
  }
}
