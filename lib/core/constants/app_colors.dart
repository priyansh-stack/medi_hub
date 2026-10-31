import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Background - Signature Warm Pale Sage / Cream from PRD mockups
  static const Color scaffoldBg = Color(0xFFF3F6EE);
  static const Color cardBg = Colors.white;
  static const Color cardSelectedBg = Color(0xFF244F38); // Deep forest green card

  // Primary - Deep Forest / Pine Green
  static const Color primary = Color(0xFF285A3E);
  static const Color primaryDark = Color(0xFF1B3D2A);
  static const Color primaryLight = Color(0xFF457C5A);
  static const Color primarySurface = Color(0xFFE8EFE5);

  // Secondary - Slate / Earthy Charcoal
  static const Color secondary = Color(0xFF1B2A22);
  static const Color secondaryLight = Color(0xFF3B4E44);

  // Text Colors
  static const Color textPrimary = Color(0xFF192820);
  static const Color textSecondary = Color(0xFF556B5F);
  static const Color textMuted = Color(0xFF88998E);
  static const Color textOnPrimary = Colors.white;

  // Borders & Form Fields
  static const Color border = Color(0xFFD6DFD5);
  static const Color borderFocused = Color(0xFF285A3E);

  // Stepper
  static const Color stepActive = Color(0xFF285A3E);
  static const Color stepInactive = Color(0xFFD0DCD2);
  static const Color stepLine = Color(0xFFCAD7CE);

  // Status & Badges
  static const Color success = Color(0xFF2E7D32);
  static const Color successBg = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFE65100);
  static const Color warningBg = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFC62828);
  static const Color errorBg = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF1565C0);
  static const Color infoBg = Color(0xFFE3F2FD);

  // Badges
  static const Color popularTagBg = Color(0xFF7A1C2C); // Wine tag for popular tier
  static const Color mockBadgeBg = Color(0xFFFEF3C7);
  static const Color mockBadgeText = Color(0xFF92400E);
  static const Color mockBadgeBorder = Color(0xFFFCD34D);
}
