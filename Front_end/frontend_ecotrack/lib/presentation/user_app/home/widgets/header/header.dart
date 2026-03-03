import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend_ecotrack/presentation/user_app/notification/notification_screen.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../controllers/profile_controller.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HeaderWidget extends StatefulWidget {
  final ProfileController controller;
  final VoidCallback? onAvatarTap;

  const HeaderWidget({super.key, required this.controller, this.onAvatarTap});

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadProfile().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  String? get _avatarNetworkUrl {
    final imageUrl = widget.controller.imageUrl;

    if (imageUrl.isEmpty) return null;

    // backend đã trả full URL → dùng luôn
    if (imageUrl.startsWith('http')) return imageUrl;

    final baseUrl = dotenv.env['API_BASE_URL']!;
    return '$baseUrl$imageUrl';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    // --- FIX: Lấy chiều cao Status Bar hiện tại ---
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    // ----------------------------------------------

    return Container(
      // --- FIX: Cộng thêm statusBarHeight vào padding top ---
      // Điều này đẩy nội dung xuống dưới tai thỏ, nhưng giữ màu nền phủ kín
      padding: EdgeInsets.fromLTRB(16, 12 + statusBarHeight, 16, 12),

      // ----------------------------------------------------
      decoration: BoxDecoration(
        color: isDesktop ? Colors.white : HomeColors.bgHeader,
        boxShadow: isDesktop
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: HomeColors.logoBorderColor,
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/images/Logo.svg',
                        width: 26,
                        height: 26,
                        colorFilter: const ColorFilter.mode(
                          AppColors.white,
                          BlendMode.srcIn,
                        ),
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
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Bảo vệ môi trường',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
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
                      child: GestureDetector(
                        onTap: () {
                          // Điều hướng sang trang thông báo
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const NotificationScreen(), // Thay bằng trang của bạn
                            ),
                          );
                        },
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
    final avatarUrl = _avatarNetworkUrl;

    Widget avatarWidget;

    if (avatarUrl == null) {
      avatarWidget = CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey[400],
        child: const Icon(Icons.person, color: AppColors.white, size: 20),
      );
    } else {
      avatarWidget = CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey[300],
        backgroundImage: NetworkImage(avatarUrl),
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

    return InkWell(
      onTap: () {
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
