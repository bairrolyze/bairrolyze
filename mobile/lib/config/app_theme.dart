import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// HomeScope design tokens — matches extension-v2 (NeighborLens)
class AppColors {
  static const bg       = Color(0xFF060B14);
  static const surface  = Color(0xFF0D1625);
  static const surface2 = Color(0xFF131F33);
  static const border   = Color(0xFF1A2845);
  static const accent   = Color(0xFF3B82F6);
  static const accent2  = Color(0xFF6C63FF);
  static const success  = Color(0xFF22C55E);
  static const warning  = Color(0xFFF59E0B);
  static const error    = Color(0xFFEF4444);

  // Light-mode counterparts. Same accent/status hues (brand consistency
  // across modes) — only surfaces and text invert.
  static const bgLight       = Color(0xFFF7F8FC);
  static const surfaceLight  = Color(0xFFFFFFFF);
  static const surface2Light = Color(0xFFF0F1F7);
  static const borderLight   = Color(0xFFE3E5EE);
}

/// Screens should read colors through this instead of hardcoding
/// AppColors.bg / AppColors.surface directly, so both themes stay correct.
/// Usage: `final c = AppPalette.of(context); c.bg`.
class AppPalette {
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color border;
  final Color textPrimary;
  final Color textSecondary; // ~65% emphasis
  final Color textTertiary;  // ~35% emphasis, captions/hints

  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
  });

  static const dark = AppPalette(
    bg: AppColors.bg,
    surface: AppColors.surface,
    surface2: AppColors.surface2,
    border: AppColors.border,
    textPrimary: Colors.white,
    textSecondary: Color(0xCCFFFFFF), // white @ ~80% (readable secondary)
    textTertiary: Color(0x66FFFFFF),  // white @ 40%
  );

  static const light = AppPalette(
    bg: AppColors.bgLight,
    surface: AppColors.surfaceLight,
    surface2: AppColors.surface2Light,
    border: AppColors.borderLight,
    textPrimary: Color(0xFF13151C),
    textSecondary: Color(0xFF4B4E5C),
    textTertiary: Color(0xFF8C8FA0),
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

class AppTheme {
  static ThemeData dark() {
    const primary   = AppColors.accent;
    const onPrimary = Colors.white;
    const surface   = AppColors.surface;

    final colorScheme = ColorScheme.dark(
      primary: primary,
      onPrimary: onPrimary,
      secondary: AppColors.accent2,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.border,
      surfaceContainerHighest: AppColors.surface2,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: -0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.12),
        inactiveTrackColor: AppColors.border,
        trackHeight: 3,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? primary : Colors.grey),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? primary.withValues(alpha: 0.4)
                : AppColors.border),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface2,
        selectedColor: primary.withValues(alpha: 0.18),
        side: const BorderSide(color: AppColors.border),
        labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: primary,
        unselectedItemColor: Colors.white38,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static ThemeData light() {
    const primary   = AppColors.accent;
    const onPrimary = Colors.white;
    const surface   = AppColors.surfaceLight;
    const onSurface = Color(0xFF13151C);

    final colorScheme = ColorScheme.light(
      primary: primary,
      onPrimary: onPrimary,
      secondary: AppColors.accent2,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: onSurface,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.borderLight,
      surfaceContainerHighest: AppColors.surface2Light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bgLight,
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: onSurface,
        displayColor: onSurface,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: surface,
        foregroundColor: onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface2Light,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface2Light,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: const TextStyle(color: Color(0xFF8C8FA0)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: -0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.12),
        inactiveTrackColor: AppColors.borderLight,
        trackHeight: 3,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? primary : Colors.grey),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? primary.withValues(alpha: 0.4)
                : AppColors.borderLight),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface2Light,
        selectedColor: primary.withValues(alpha: 0.14),
        side: const BorderSide(color: AppColors.borderLight),
        labelStyle: const TextStyle(color: Color(0xFF13151C), fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor: primary,
        unselectedItemColor: Color(0xFF8C8FA0),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
