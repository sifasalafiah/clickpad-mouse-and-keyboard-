import 'package:flutter/material.dart';

enum AppThemeMode {
  light,
  dark,
}

class ThemePalette {
  final String name;
  final String subtitle;
  final bool isPro;
  final bool isLight;
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color primary;
  final Color primaryLight;
  final Color accent;
  final Color border;
  final Color touchpadCanvas;
  final Color touchRipple;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  const ThemePalette({
    required this.name,
    required this.subtitle,
    required this.isPro,
    required this.isLight,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.primary,
    required this.primaryLight,
    required this.accent,
    required this.border,
    required this.touchpadCanvas,
    required this.touchRipple,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });
}

class AppColors {
  static AppThemeMode currentTheme = AppThemeMode.dark;

  static const Map<AppThemeMode, ThemePalette> palettes = {
    // 1. Light Mode - Clean, crisp, high-contrast Slate & Indigo
    AppThemeMode.light: ThemePalette(
      name: 'Slate Light',
      subtitle: 'Crisp clean slate & indigo light mode',
      isPro: false,
      isLight: true,
      background: Color(0xFFF1F5F9),
      surface: Color(0xFFFFFFFF),
      surfaceElevated: Color(0xFFE2E8F0),
      primary: Color(0xFF4F46E5),
      primaryLight: Color(0xFF6366F1),
      accent: Color(0xFF4338CA),
      border: Color(0xFFCBD5E1),
      touchpadCanvas: Color(0xFFE8EEF5),
      touchRipple: Color(0x264F46E5),
      textPrimary: Color(0xFF0F172A),
      textSecondary: Color(0xFF334155),
      textMuted: Color(0xFF64748B),
    ),

    // 2. Dark Mode - Deep, sharp Midnight Slate with vivid Indigo accents (Default)
    AppThemeMode.dark: ThemePalette(
      name: 'Midnight Dark',
      subtitle: 'Deep midnight slate & vivid indigo (Default)',
      isPro: false,
      isLight: false,
      background: Color(0xFF0B0F19),
      surface: Color(0xFF151C2C),
      surfaceElevated: Color(0xFF1E293B),
      primary: Color(0xFF6366F1),
      primaryLight: Color(0xFF818CF8),
      accent: Color(0xFF4F46E5),
      border: Color(0xFF334155),
      touchpadCanvas: Color(0xFF0F172A),
      touchRipple: Color(0x336366F1),
      textPrimary: Color(0xFFF8FAFC),
      textSecondary: Color(0xFFCBD5E1),
      textMuted: Color(0xFF94A3B8),
    ),
  };

  static ThemePalette get palette =>
      palettes[currentTheme] ?? palettes[AppThemeMode.dark]!;

  static void applyTheme(AppThemeMode mode) {
    currentTheme = mode;
  }

  // Primary Palette
  static Color get background => palette.background;
  static Color get surface => palette.surface;
  static Color get surfaceElevated => palette.surfaceElevated;
  static Color get surfaceGlass => palette.surfaceElevated.withAlpha(50);

  // Accents
  static Color get primary => palette.primary;
  static Color get primaryLight => palette.primaryLight;
  static Color get accent => palette.accent;
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Neutral Text & Icons
  static Color get textPrimary => palette.textPrimary;
  static Color get textSecondary => palette.textSecondary;
  static Color get textMuted => palette.textMuted;
  static Color get border => palette.border;
  static Color get borderSubtle =>
      palette.isLight ? const Color(0x1F0F172A) : const Color(0x1F94A3B8);

  // Touchpad visual highlights
  static Color get touchpadCanvas => palette.touchpadCanvas;
  static Color get touchRipple => palette.touchRipple;
}
