import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';

class QrScanCard extends StatelessWidget {
  const QrScanCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: HomeColors.cardBorder,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderColor, width: 2),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/qr.svg',
                  width: 28,
                  height: 28,
                  colorFilter: const ColorFilter.mode(
                    AppColors.textLogo,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Title
            const Text(
              'Check-in',
              style: TextStyle(
                color: AppColors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            // Subtitle
            const Text(
              'Quét QR chiến dịch',
              style: TextStyle(color: AppColors.black, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
