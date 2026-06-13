import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF4A40D9);
  static const Color accent = Color(0xFFFFC857);
  static const Color coral = Color(0xFFFF6B6B);
  static const Color mint = Color(0xFF4ECDC4);
  static const Color skyBlue = Color(0xFF6FC3DF);
  static const Color cream = Color(0xFFFFF8E7);
  static const Color inkDark = Color(0xFF2D2A4A);
  static const Color inkSoft = Color(0xFF6B6B8D);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFFF5252);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);

    final textTheme = GoogleFonts.fredokaTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.fredoka(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: AppColors.inkDark,
      ),
      headlineMedium: GoogleFonts.fredoka(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.inkDark,
      ),
      titleLarge: GoogleFonts.fredoka(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.inkDark,
      ),
      bodyLarge: GoogleFonts.nunito(
        fontSize: 16,
        height: 1.5,
        color: AppColors.inkDark,
      ),
      bodyMedium: GoogleFonts.nunito(
        fontSize: 14,
        height: 1.5,
        color: AppColors.inkSoft,
      ),
      labelLarge: GoogleFonts.fredoka(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.cream,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.cream,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.fredoka(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.inkDark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.fredoka(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
