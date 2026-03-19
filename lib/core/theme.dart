import 'package:flutter/material.dart';

ThemeData buildKyyTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  const purple = Color(0xFF6B4EFF);
  const violet = Color(0xFF9D7EFF);
  const teal = Color(0xFF0ECB81);
  const amber = Color(0xFFFFB800);
  const coral = Color(0xFFFF5A5F);

  final baseScheme = ColorScheme.fromSeed(
    seedColor: purple,
    brightness: brightness,
  );

  final colorScheme = baseScheme.copyWith(
    primary: purple,
    secondary: violet,
    tertiary: amber,
    error: coral,
    primaryContainer: Color.lerp(purple, Colors.white, isDark ? 0.18 : 0.82)!,
    secondaryContainer: Color.lerp(violet, Colors.white, isDark ? 0.16 : 0.84)!,
    surface: isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8F7FF),
    surfaceContainerHighest:
        isDark ? const Color(0xFF14141C) : const Color(0xFFF0EEFF),
    outlineVariant: isDark ? const Color(0xFF2A2A3A) : const Color(0xFFD6D1FF),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      centerTitle: false,
      scrolledUnderElevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(vertical: 8),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.55)),
      labelStyle: TextStyle(color: colorScheme.onSurface),
      backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: colorScheme.surface.withValues(alpha: isDark ? 0.88 : 0.92),
      indicatorColor: colorScheme.primary.withValues(alpha: 0.16),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    ),
    extensions: const [
      KyyBrand(
        purple: purple,
        violet: violet,
        success: teal,
        warning: amber,
        danger: coral,
      ),
    ],
  );
}

class KyyBrand extends ThemeExtension<KyyBrand> {
  const KyyBrand({
    required this.purple,
    required this.violet,
    required this.success,
    required this.warning,
    required this.danger,
  });

  final Color purple;
  final Color violet;
  final Color success;
  final Color warning;
  final Color danger;

  LinearGradient get primaryGradient => LinearGradient(
        colors: [purple, violet],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  @override
  KyyBrand copyWith({
    Color? purple,
    Color? violet,
    Color? success,
    Color? warning,
    Color? danger,
  }) {
    return KyyBrand(
      purple: purple ?? this.purple,
      violet: violet ?? this.violet,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
    );
  }

  @override
  KyyBrand lerp(ThemeExtension<KyyBrand>? other, double t) {
    if (other is! KyyBrand) return this;
    return KyyBrand(
      purple: Color.lerp(purple, other.purple, t)!,
      violet: Color.lerp(violet, other.violet, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}
