import 'package:flutter/material.dart';

enum AppThemeMode {
  midnightSlateLight,
  midnightSlateDark,
  oledPureWhite,
  oledPureBlack,
  cyberpunkPastel,
  cyberpunkNeon,
  emeraldPebbleLight,
  emeraldPebbleDark,
  sunsetAmberLight,
  sunsetAmberDark,
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
  static AppThemeMode currentTheme = AppThemeMode.midnightSlateLight;

  static const Map<AppThemeMode, ThemePalette> palettes = {
    // 1. Midnight Slate (Light) - FREE / UNLOCKED (Default)
    AppThemeMode.midnightSlateLight: ThemePalette(
      name: 'Midnight Slate',
      subtitle: 'Clean crisp indigo & slate light mode (Default)',
      isPro: false,
      isLight: true,
      background: Color(0xFFF1F5F9),
      surface: Color(0xFFFFFFFF),
      surfaceElevated: Color(0xFFE2E8F0),
      primary: Color(0xFF4F46E5),
      primaryLight: Color(0xFF6366F1),
      accent: Color(0xFF7C3AED),
      border: Color(0xFFCBD5E1),
      touchpadCanvas: Color(0xFFE8EEF5),
      touchRipple: Color(0x334F46E5),
      textPrimary: Color(0xFF0F172A),
      textSecondary: Color(0xFF475569),
      textMuted: Color(0xFF64748B),
    ),

    // 2. Midnight Slate (Dark) - FREE / UNLOCKED
    AppThemeMode.midnightSlateDark: ThemePalette(
      name: 'Midnight Slate',
      subtitle: 'Modern deep indigo & navy dark mode',
      isPro: false,
      isLight: false,
      background: Color(0xFF0B0F19),
      surface: Color(0xFF151C2C),
      surfaceElevated: Color(0xFF1E293B),
      primary: Color(0xFF6366F1),
      primaryLight: Color(0xFF818CF8),
      accent: Color(0xFF8B5CF6),
      border: Color(0xFF334155),
      touchpadCanvas: Color(0xFF0F172A),
      touchRipple: Color(0x406366F1),
      textPrimary: Color(0xFFF8FAFC),
      textSecondary: Color(0xFF94A3B8),
      textMuted: Color(0xFF64748B),
    ),

    // 3. OLED Pure White (Light) - PRO
    AppThemeMode.oledPureWhite: ThemePalette(
      name: 'OLED Pure White',
      subtitle: 'Minimalist true paper white & high-contrast cyan',
      isPro: true,
      isLight: true,
      background: Color(0xFFFFFFFF),
      surface: Color(0xFFF8FAFC),
      surfaceElevated: Color(0xFFF1F5F9),
      primary: Color(0xFF0891B2),
      primaryLight: Color(0xFF06B6D4),
      accent: Color(0xFF059669),
      border: Color(0xFFE2E8F0),
      touchpadCanvas: Color(0xFFF8FAFC),
      touchRipple: Color(0x330891B2),
      textPrimary: Color(0xFF020617),
      textSecondary: Color(0xFF334155),
      textMuted: Color(0xFF64748B),
    ),

    // 4. OLED Pure Black (Dark) - PRO
    AppThemeMode.oledPureBlack: ThemePalette(
      name: 'OLED Pure Black',
      subtitle: 'True 0% Black for maximum AMOLED battery savings',
      isPro: true,
      isLight: false,
      background: Color(0xFF000000),
      surface: Color(0xFF0A0A0C),
      surfaceElevated: Color(0xFF141418),
      primary: Color(0xFF00E5FF),
      primaryLight: Color(0xFF80F0FF),
      accent: Color(0xFF00E676),
      border: Color(0xFF22242B),
      touchpadCanvas: Color(0xFF030304),
      touchRipple: Color(0x4000E5FF),
      textPrimary: Color(0xFFF8FAFC),
      textSecondary: Color(0xFF94A3B8),
      textMuted: Color(0xFF64748B),
    ),

    // 5. Cyberpunk Pastel (Light) - PRO
    AppThemeMode.cyberpunkPastel: ThemePalette(
      name: 'Cyberpunk Pastel',
      subtitle: 'Luminous pastel orchid & energetic fuchsia',
      isPro: true,
      isLight: true,
      background: Color(0xFFFAF5FF),
      surface: Color(0xFFFFFFFF),
      surfaceElevated: Color(0xFFF3E8FF),
      primary: Color(0xFFC026D3),
      primaryLight: Color(0xFFD946EF),
      accent: Color(0xFF7C3AED),
      border: Color(0xFFE9D5FF),
      touchpadCanvas: Color(0xFFF5EEFD),
      touchRipple: Color(0x33C026D3),
      textPrimary: Color(0xFF3B0764),
      textSecondary: Color(0xFF6B21A8),
      textMuted: Color(0xFF9333EA),
    ),

    // 6. Cyberpunk Neon (Dark) - PRO
    AppThemeMode.cyberpunkNeon: ThemePalette(
      name: 'Cyberpunk Neon',
      subtitle: 'High contrast electric fuchsia & violet glow',
      isPro: true,
      isLight: false,
      background: Color(0xFF0D0616),
      surface: Color(0xFF180D26),
      surfaceElevated: Color(0xFF25153A),
      primary: Color(0xFFD946EF),
      primaryLight: Color(0xFFF0ABFC),
      accent: Color(0xFF8B5CF6),
      border: Color(0xFF3C205C),
      touchpadCanvas: Color(0xFF11081D),
      touchRipple: Color(0x40D946EF),
      textPrimary: Color(0xFFF8FAFC),
      textSecondary: Color(0xFF94A3B8),
      textMuted: Color(0xFF64748B),
    ),

    // 7. Emerald Pebble (Light) - PRO
    AppThemeMode.emeraldPebbleLight: ThemePalette(
      name: 'Emerald Pebble',
      subtitle: 'Fresh botanical sage & calming spring greenery',
      isPro: true,
      isLight: true,
      background: Color(0xFFF0FDF4),
      surface: Color(0xFFFFFFFF),
      surfaceElevated: Color(0xFFDCFCE7),
      primary: Color(0xFF059669),
      primaryLight: Color(0xFF10B981),
      accent: Color(0xFF0D9488),
      border: Color(0xFFBBF7D0),
      touchpadCanvas: Color(0xFFEAF9EE),
      touchRipple: Color(0x33059669),
      textPrimary: Color(0xFF064E3B),
      textSecondary: Color(0xFF065F46),
      textMuted: Color(0xFF047857),
    ),

    // 8. Emerald Pebble (Dark) - PRO
    AppThemeMode.emeraldPebbleDark: ThemePalette(
      name: 'Emerald Pebble',
      subtitle: 'Soothing forest green & pebble aesthetic',
      isPro: true,
      isLight: false,
      background: Color(0xFF07140E),
      surface: Color(0xFF0E2218),
      surfaceElevated: Color(0xFF163224),
      primary: Color(0xFF10B981),
      primaryLight: Color(0xFF6EE7B7),
      accent: Color(0xFF059669),
      border: Color(0xFF234C38),
      touchpadCanvas: Color(0xFF0A1B13),
      touchRipple: Color(0x4010B981),
      textPrimary: Color(0xFFF8FAFC),
      textSecondary: Color(0xFF94A3B8),
      textMuted: Color(0xFF64748B),
    ),

    // 9. Sunset Amber (Light) - PRO
    AppThemeMode.sunsetAmberLight: ThemePalette(
      name: 'Sunset Amber',
      subtitle: 'Warm morning sunlight & toasted honey amber',
      isPro: true,
      isLight: true,
      background: Color(0xFFFFFBEB),
      surface: Color(0xFFFFFFFF),
      surfaceElevated: Color(0xFFFEF3C7),
      primary: Color(0xFFD97706),
      primaryLight: Color(0xFFF59E0B),
      accent: Color(0xFFEA580C),
      border: Color(0xFFFDE68A),
      touchpadCanvas: Color(0xFFFFF7DC),
      touchRipple: Color(0x33D97706),
      textPrimary: Color(0xFF451A03),
      textSecondary: Color(0xFF78350F),
      textMuted: Color(0xFF92400E),
    ),

    // 10. Sunset Amber (Dark) - PRO
    AppThemeMode.sunsetAmberDark: ThemePalette(
      name: 'Sunset Amber',
      subtitle: 'Warm cozy amber glow and dark bronze tones',
      isPro: true,
      isLight: false,
      background: Color(0xFF140D07),
      surface: Color(0xFF22160C),
      surfaceElevated: Color(0xFF332112),
      primary: Color(0xFFF59E0B),
      primaryLight: Color(0xFFFCD34D),
      accent: Color(0xFFFB923C),
      border: Color(0xFF4C331B),
      touchpadCanvas: Color(0xFF1A1109),
      touchRipple: Color(0x40F59E0B),
      textPrimary: Color(0xFFF8FAFC),
      textSecondary: Color(0xFF94A3B8),
      textMuted: Color(0xFF64748B),
    ),
  };

  static ThemePalette get palette =>
      palettes[currentTheme] ?? palettes[AppThemeMode.midnightSlateLight]!;

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

  // Neutral Text & Icons (Dynamic based on selected palette)
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
