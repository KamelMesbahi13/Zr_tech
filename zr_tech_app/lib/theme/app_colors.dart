import 'package:flutter/material.dart';

class AppColors {
  // ── Light Background ──────────────────────────────────────────
  static const Color background = Colors.white;
  static const Color surface = Color(0xFFF8F9FB);
  static const Color surfaceAlt = Color(0xFFF0F2F5);
  static const Color surfaceCard = Colors.white;
  static const Color surfaceInput = Color(0xFFF5F6F8);

  // ── Primary (from logo) ───────────────────────────────────────
  static const Color primary = Color(0xFF1DA1F2);
  static const Color primaryDark = Color(0xFF0D8BD9);
  static const Color primaryLight = Color(0xFF4DB8F5);

  // ── Borders ───────────────────────────────────────────────────
  static const Color border = Color(0xFFE2E4E9);
  static const Color borderSubtle = Color(0xFFEEEFF2);

  // ── Text ──────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF555566);
  static const Color textMuted = Color(0xFF888899);
  static const Color textHint = Color(0xFFAAAABB);

  // ── Accent ────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // ── Legacy aliases (for backward compatibility) ───────────────
  static const Color backgroundDark = background;
  static const Color surfaceDark = surface;
  static const Color surfaceDarkAlt = surfaceAlt;
  static const Color borderDark = border;
  static const Color textWhite = textPrimary;
  static const Color textSlate300 = textSecondary;
  static const Color textSlate400 = textMuted;
  static const Color textSlate500 = textHint;
  static const Color cyan = primaryLight;
  static const Color tabActive = Color(0xFFE8F4FD);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primaryDark],
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
  );

  static const LinearGradient primaryGradientLTR = LinearGradient(
    colors: [primaryLight, primaryDark],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient borderGradient = LinearGradient(
    colors: [primaryLight, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
