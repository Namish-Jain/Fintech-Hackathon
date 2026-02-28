import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const Color deepNavy     = Color(0xFF0A0E21);
  static const Color cardSurface  = Color(0xFF0F1535);
  static const Color cardBorder   = Color(0xFF1E2A4A);
  static const Color neonGreen    = Color(0xFF00E676);
  static const Color neonGreenDim = Color(0x2600E676);

  static const Color textPrimary   = Color(0xFFF0F4FF);
  static const Color textSecondary = Color(0xFF8892B0);

  static const Color positive = Color(0xFF00E676);
  static const Color negative = Color(0xFFFF5370);
  static const Color warning  = Color(0xFFFFCB6B);
  static const Color info     = Color(0xFF82AAFF);

  // Category badge colours
  static const Map<String, Color> categoryColors = {
    'Markets':         Color(0xFF82AAFF),
    'Crypto':          Color(0xFFFFCB6B),
    'Economy':         Color(0xFF00E676),
    'Policy':          Color(0xFFC792EA),
    'Company Moves':   Color(0xFF89DDFF),
    'Money & Credit':  Color(0xFFFF5370),
    'Personal Finance':Color(0xFFADDB67),
  };
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.deepNavy,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.neonGreen,
        secondary: AppColors.info,
        surface: AppColors.cardSurface,
        onPrimary: AppColors.deepNavy,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme.copyWith(
          headlineLarge: GoogleFonts.spaceGrotesk(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
            height: 1.3,
          ),
          bodyLarge: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
            height: 1.65,
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
          labelLarge: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
