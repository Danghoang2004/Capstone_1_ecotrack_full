import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class WelcomeDialog extends StatelessWidget {
  final String fullName;
  final int points;

  const WelcomeDialog({
    super.key,
    required this.fullName,
    required this.points,
  });

  static Future<void> show(
    BuildContext context, {
    required String fullName,
    required int points,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WelcomeDialog(
          fullName: fullName,
          points: points,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: isMobile ? screenWidth * 0.9 : 400,
        padding: EdgeInsets.all(isMobile ? 20 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lottie animation
            SizedBox(
              height: isMobile ? 120 : 150,
              child: Lottie.asset(
                "assets/lotties/animations/success.json",
                repeat: false,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Chào mừng $fullName đến với EcoTrack',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              'Bạn nhận được $points điểm tài khoản mới!',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // OK Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5EAC24),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Bắt đầu',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

