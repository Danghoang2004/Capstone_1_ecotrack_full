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

  // Palette riêng cho admin web
  static const Color adminBackground = Color(0xFFF3F6F2);
  static const Color adminSurface = Color(0xFFFFFFFF);
  static const Color adminSurfaceSoft = Color(0xFFF9FCF8);
  static const Color adminSurfaceMuted = Color(0xFFEEF3EF);
  static const Color adminBorder = Color(0xFFD6E0D8);
  static const Color adminBorderStrong = Color(0xFFBCCDCC);
  static const Color adminAccent = Color(0xFF1FA971);
  static const Color adminAccentDeep = Color(0xFF116A5B);
  static const Color adminAccentSoft = Color(0xFFD9F3E8);
  static const Color adminAccentSky = Color(0xFF2F8DE4);
  static const Color adminAccentWarm = Color(0xFFFF9352);
  static const Color adminTextPrimary = Color(0xFF17201C);
  static const Color adminTextSecondary = Color(0xFF66746D);

  static LinearGradient get adminBackgroundGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF7F9F6), Color(0xFFEAF0EA)],
  );

  static LinearGradient get adminHeroGradient => const LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF1FA971), Color(0xFF1B7EA8)],
  );

  static LinearGradient get adminSidebarGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0F3D34), Color(0xFF0A2A2F)],
  );

  static LinearGradient get adminMenuSelectedGradient => const LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF31BC84), Color(0xFF2F8DE4)],
  );
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
