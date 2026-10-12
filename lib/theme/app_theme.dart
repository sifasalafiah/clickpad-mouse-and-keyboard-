import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme => getTheme(AppThemeMode.midnightSlateLight);
  static ThemeData get darkTheme => getTheme(AppThemeMode.midnightSlateDark);

  static ThemeData getTheme(AppThemeMode mode) {
    AppColors.applyTheme(mode);
    final palette = AppColors.palettes[mode] ??
        AppColors.palettes[AppThemeMode.midnightSlateDark]!;

    final baseTextTheme = palette.isLight
        ? ThemeData.light().textTheme
        : ThemeData.dark().textTheme;
    final googleTextTheme = GoogleFonts.interTextTheme(baseTextTheme);

    final colorScheme = palette.isLight
        ? ColorScheme.light(
            primary: palette.primary,
            secondary: palette.accent,
            surface: palette.surface,
            error: AppColors.error,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: palette.textPrimary,
          )
        : ColorScheme.dark(
            primary: palette.primary,
            secondary: palette.accent,
            surface: palette.surface,
            error: AppColors.error,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: palette.textPrimary,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: palette.isLight ? Brightness.light : Brightness.dark,
      scaffoldBackgroundColor: palette.background,
      colorScheme: colorScheme,
      textTheme: googleTextTheme.copyWith(
        headlineMedium: googleTextTheme.headlineMedium?.copyWith(
          color: palette.textPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        titleLarge: googleTextTheme.titleLarge?.copyWith(
          color: palette.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: googleTextTheme.titleMedium?.copyWith(
          color: palette.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: googleTextTheme.bodyLarge?.copyWith(
          color: palette.textPrimary,
        ),
        bodyMedium: googleTextTheme.bodyMedium?.copyWith(
          color: palette.textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: palette.border, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: palette.textPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: palette.surface,
        selectedItemColor: palette.primary,
        unselectedItemColor: palette.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: palette.primary,
        inactiveTrackColor: palette.surfaceElevated,
        thumbColor: palette.primaryLight,
        overlayColor: palette.primary.withAlpha(50),
        trackHeight: 4,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
