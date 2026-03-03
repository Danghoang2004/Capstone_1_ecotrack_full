import 'package:flutter/material.dart';

class AppColors {
  // Màu dùng chung
  static const Color black = Colors.black;
  static const Color white = Colors.white;
  static const Color textLogo = Color(0xFF4D7817);
  static const Color borderColor = Color(0xFF3C9541);
  static const Color primaryGreen = Color(0xFF2E7D32); 
  static const Color backgroundLight = Color.fromARGB(255, 238, 239, 238); 
  static const Color textPrimary = Color(0xFF1B1B1B);
  static const Color textSecondary = Color(0xFF757575);
}

class HomeColors {
  static const Color background = Color(0xFFF6FEF3);
  static const Color bgHeader = Color(0x1A2E7D32);
  static const Color logoBorderColor = Color(0xFF3C9541);
  static const Color badgeBg = Color(0xFFC0E1AE);
  static const Color cardBorder = Color(0xFFE1F1DF);
  static LinearGradient get bgWelcome => const LinearGradient(
    colors: [Color(0xFF3C9541), Color(0xB3132F14)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
