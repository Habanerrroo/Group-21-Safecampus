import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary: Deep Midnight Blue - security & trust
  static const Color primary = Color(0xFF0A0F1F);
  static const Color primaryLight = Color(0xFF1A1F3A);
  static const Color primaryLighter = Color(0xFF2A2F4A);

  // Accent: Safety Orange - emergency states
  static const Color accent = Color(0xFFFF7A1A);
  static const Color accentLight = Color(0xFFFFB266);

  // Secondary: Cool Teal - neutrality & information
  static const Color secondary = Color(0xFF1FBFAE);
  static const Color secondaryLight = Color(0xFF4DD9C4);

  // Success: Forest Green - resolved/safe states
  static const Color success = Color(0xFF1E7643);
  static const Color successLight = Color(0xFF3A9F66);

  // Surface colors
  static const Color surface = Color(0xFF151B33);
  static const Color surfaceAlt = Color(0xFF1F2643);
  static const Color border = Color(0xFF2A2F4A);
  static const Color borderAlt = Color(0xFF3A3F5A);

  // Text colors
  static const Color foreground = Color(0xFFF4F5F7);
  static const Color foregroundMuted = Color(0xFFB8B8C4);
  static const Color foregroundLight = Color(0xFF9CA3AF);

  // Alert colors
  static const Color critical = Color(0xFF8B0000);
  static const Color warning = Color(0xFFFF7A1A);
  static const Color info = Color(0xFF1FBFAE);
  static const Color allClear = Color(0xFF3A9F66);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.primary,
      
      colorScheme: const ColorScheme.dark(
        primary: AppColors.secondary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.critical,
        onPrimary: AppColors.primary,
        onSecondary: AppColors.primary,
        onSurface: AppColors.foreground,
        onError: Colors.white,
      ),

      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme.apply(
          bodyColor: AppColors.foreground,
          displayColor: AppColors.foreground,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.primary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.foreground,
          side: const BorderSide(color: AppColors.border, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.secondary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.foregroundLight),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
    );
  }
}

