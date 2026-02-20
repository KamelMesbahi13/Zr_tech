import 'package:flutter/material.dart';

class AppColors {
  // Background
  static const Color backgroundDark = Color(0xFF0A101D);
  static const Color surfaceDark = Color(0xFF121B2E);
  static const Color surfaceDarkAlt = Color(0xFF162032);
  static const Color surfaceCard = Color(0xFF131B2B);
  static const Color surfaceInput = Color(0xFF161E2E);

  // Primary
  static const Color primary = Color(0xFF0D93F2);
  static const Color primaryDark = Color(0xFF005CFF);
  static const Color primaryLight = Color(0xFF00D2FF);
  static const Color cyan = Color(0xFF00E1FF);

  // Borders
  static const Color borderDark = Color(0xFF1E2A3B);
  static const Color borderSubtle = Color(0x0DFFFFFF); // white/5

  // Text
  static const Color textWhite = Colors.white;
  static const Color textMuted = Color(0xFF9CADBA);
  static const Color textSlate300 = Color(0xFFCBD5E1);
  static const Color textSlate400 = Color(0xFF94A3B8);
  static const Color textSlate500 = Color(0xFF64748B);

  // Tab active background
  static const Color tabActive = Color(0xFF232E42);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primaryDark],
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
  );

  static const LinearGradient primaryGradientLTR = LinearGradient(
    colors: [cyan, primaryDark],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient borderGradient = LinearGradient(
    colors: [primaryLight, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
