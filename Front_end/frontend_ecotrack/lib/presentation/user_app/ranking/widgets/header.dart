import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

class RankingHeader extends StatelessWidget implements PreferredSizeWidget {
  const RankingHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      forceMaterialTransparency: true,
      centerTitle: true,
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

      title: const Text(
        'Bảng xếp hạng',
        style: TextStyle(
          color: AppColors.black,
          fontSize: 21.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
