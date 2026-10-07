import 'package:flutter/material.dart';

enum AppThemeMode {
  midnightSlate,
  oledPureBlack,
  cyberpunkNeon,
  emeraldPebble,
  sunsetAmber,
}

class ThemePalette {
  final String name;
  final String subtitle;
  final bool isPro;
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color primary;
  final Color primaryLight;
  final Color accent;
  final Color border;
  final Color touchpadCanvas;
  final Color touchRipple;

  const ThemePalette({
    required this.name,
    required this.subtitle,
    required this.isPro,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.primary,
    required this.primaryLight,
    required this.accent,
    required this.border,
    required this.touchpadCanvas,
    required this.touchRipple,
  });
}

class AppColors {
  static AppThemeMode currentTheme = AppThemeMode.midnightSlate;

  static const Map<AppThemeMode, ThemePalette> palettes = {
    AppThemeMode.midnightSlate: ThemePalette(
      name: 'Midnight Slate',
      subtitle: 'Modern deep indigo & navy dark mode (Default)',
      isPro: false,
      background: Color(0xFF0B0F19),
      surface: Color(0xFF151C2C),
      surfaceElevated: Color(0xFF1E293B),
      primary: Color(0xFF6366F1),
      primaryLight: Color(0xFF818CF8),
      accent: Color(0xFF8B5CF6),
      border: Color(0xFF334155),
      touchpadCanvas: Color(0xFF0F172A),
      touchRipple: Color(0x406366F1),
    ),
    AppThemeMode.oledPureBlack: ThemePalette(
      name: 'OLED Pure Black',
      subtitle: 'True 0% Black for maximum AMOLED battery savings',
      isPro: true,
      background: Color(0xFF000000),
      surface: Color(0xFF0A0A0C),
      surfaceElevated: Color(0xFF141418),
      primary: Color(0xFF00E5FF),
      primaryLight: Color(0xFF80F0FF),
      accent: Color(0xFF00E676),
      border: Color(0xFF22242B),
      touchpadCanvas: Color(0xFF030304),
      touchRipple: Color(0x4000E5FF),
    ),
    AppThemeMode.cyberpunkNeon: ThemePalette(
      name: 'Cyberpunk Neon',
      subtitle: 'High contrast electric fuchsia & violet glow',
      isPro: true,
      background: Color(0xFF0D0616),
      surface: Color(0xFF180D26),
      surfaceElevated: Color(0xFF25153A),
      primary: Color(0xFFD946EF),
      primaryLight: Color(0xFFF0ABFC),
      accent: Color(0xFF8B5CF6),
      border: Color(0xFF3C205C),
      touchpadCanvas: Color(0xFF11081D),
      touchRipple: Color(0x40D946EF),
    ),
    AppThemeMode.emeraldPebble: ThemePalette(
      name: 'Emerald Pebble',
      subtitle: 'Soothing forest green & pebble aesthetic',
      isPro: true,
      background: Color(0xFF07140E),
      surface: Color(0xFF0E2218),
      surfaceElevated: Color(0xFF163224),
      primary: Color(0xFF10B981),
      primaryLight: Color(0xFF6EE7B7),
      accent: Color(0xFF059669),
      border: Color(0xFF234C38),
      touchpadCanvas: Color(0xFF0A1B13),
      touchRipple: Color(0x4010B981),
    ),
    AppThemeMode.sunsetAmber: ThemePalette(
      name: 'Sunset Amber',
      subtitle: 'Warm cozy amber glow and dark bronze tones',
      isPro: true,
      background: Color(0xFF140D07),
      surface: Color(0xFF22160C),
      surfaceElevated: Color(0xFF332112),
      primary: Color(0xFFF59E0B),
      primaryLight: Color(0xFFFCD34D),
      accent: Color(0xFFFB923C),
      border: Color(0xFF4C331B),
      touchpadCanvas: Color(0xFF1A1109),
      touchRipple: Color(0x40F59E0B),
    ),
  };

  static ThemePalette get palette => palettes[currentTheme] ?? palettes[AppThemeMode.midnightSlate]!;

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
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Rose Red

  // Neutral Text & Icons
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static Color get border => palette.border;
  static const Color borderSubtle = Color(0x1F94A3B8);

  // Touchpad visual highlights
  static Color get touchpadCanvas => palette.touchpadCanvas;
  static Color get touchRipple => palette.touchRipple;
}
