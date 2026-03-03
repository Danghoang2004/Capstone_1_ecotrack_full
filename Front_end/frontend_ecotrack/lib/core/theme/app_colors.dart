import 'package:flutter/material.dart';

class AppColors {
  // Màu dùng chung
  static const Color black = Colors.black;
  static const Color white = Colors.white;
  static const Color textLogo = Color(0xFF2E7D32);
  static const Color borderColor = Color(0xFF3C9541);
}

class HomeColors {
  // Nền Home: #A0F87D với ~9% opacity → ARGB: 0x17A0F87D
  static const Color background = Color(0x17A0F87D);

  // Header: #2E7D32 với ~10.2% opacity → ARGB: 0x1A2E7D32
  static const Color bgHeader = Color(0x1A2E7D32);
  static const Color logoBorderColor = Color(0xFF2E7D32);
  static const Color badgeBg = Color(0xFFC0E1AE);
  static const Color cardBorder = Color(0xFFE1F1DF);
  static LinearGradient get bgWelcome => const LinearGradient(
    colors: [Color(0xFF3C9541), Color(0xFF145020)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
