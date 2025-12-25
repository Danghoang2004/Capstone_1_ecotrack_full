import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';

class RankingHeader extends StatelessWidget implements PreferredSizeWidget {
  const RankingHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: HomeColors.bgHeader,
      elevation: 0,
      automaticallyImplyLeading: false,

      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),

      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.black),
        onPressed: () => Navigator.pop(context),
      ),

      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bảng xếp hạng',
            style: TextStyle(
              color: AppColors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Thành tích môi trường',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),

      actions: [
        Row(
          children: [
            SvgPicture.asset(
              'assets/images/Logo.svg',
              width: 22,
              height: 22,
              colorFilter: const ColorFilter.mode(
                Color(0xFF3C9541),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'Eco Track',
              style: TextStyle(
                color: Color(0xFF3C9541),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ],
    );
  }
}
