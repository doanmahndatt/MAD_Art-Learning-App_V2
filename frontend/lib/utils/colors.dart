import 'package:flutter/material.dart';

class AppColors {
  // ── Light mode ──────────────────────────────────────────────
  static const primary        = Color(0xFF9B8FFF); // lavender pastel
  static const primaryLight   = Color(0xFFEDE9FF);
  static const secondary      = Color(0xFFFFABC8); // blush pink pastel
  static const secondaryLight = Color(0xFFFFEDF4);
  static const accent         = Color(0xFF8FD9C8); // mint pastel
  static const accentLight    = Color(0xFFDFF7F2);

  static const background     = Color(0xFFF6F4FF);
  static const surface        = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFFDF6FF);

  static const text           = Color(0xFF2C2550);
  static const textLight      = Color(0xFF9E97C0);
  static const textHint       = Color(0xFFBFB9DC);

  static const border         = Color(0xFFEDE8FB);
  static const like           = Color(0xFFFF7BAC);
  static const gold           = Color(0xFFFFCF77);

  // ── Dark mode ────────────────────────────────────────────────
  static const darkBackground     = Color(0xFF1A1730);
  static const darkSurface        = Color(0xFF241F3D);
  static const darkSurfaceVariant = Color(0xFF2E2850);
  static const darkText           = Color(0xFFF0EEFF);
  static const darkTextLight      = Color(0xFF9B93C8);
  static const darkBorder         = Color(0xFF3A3360);

  // ── Gradients ────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFB8AFFF), Color(0xFF9B8FFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFFEDE9FF), Color(0xFFFFEDF4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient darkHeaderGradient = LinearGradient(
    colors: [Color(0xFF2E2850), Color(0xFF241F3D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}