import 'package:flutter/material.dart';
import 'campus_companion_theme.dart';

/// Campus Companion Design System: slate neutrals with the brand green as the
/// primary color in both themes (see CampusColors). Institution branding is a
/// secondary accent at specific surfaces (institution badge, Digital ID card),
/// not the whole app's chrome. CampusCompanionTheme holds the shared tokens
/// (card radius, muted text, accent) both modes pull from.
class AppTheme {
  AppTheme._();

  static TextTheme _textTheme(TextTheme base, Color ink) => base
      .copyWith(
        headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.2),
        titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      )
      .apply(bodyColor: ink, displayColor: ink);

  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      primary: CampusColors.brand,
      onPrimary: Colors.white,
      primaryContainer: CampusColors.brandSoft,
      onPrimaryContainer: CampusColors.brandDeep,
      secondary: CampusColors.slate600,
      onSecondary: Colors.white,
      secondaryContainer: CampusColors.slate200,
      onSecondaryContainer: CampusColors.slate800,
      tertiary: CampusColors.brandLight,
      onTertiary: CampusColors.brandDeep,
      surface: Colors.white,
      onSurface: CampusColors.slate900,
      surfaceContainerHighest: CampusColors.slate100,
      onSurfaceVariant: CampusColors.slate500,
      outline: CampusColors.slate300,
      outlineVariant: CampusColors.slate200,
      error: CampusColors.error,
      onError: Colors.white,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: colorScheme);

    return base.copyWith(
      scaffoldBackgroundColor: CampusColors.canvas,
      textTheme: _textTheme(base.textTheme, CampusColors.slate900),
      extensions: const [CampusCompanionTheme.light],
      appBarTheme: AppBarTheme(
        backgroundColor: CampusColors.canvas,
        foregroundColor: CampusColors.slate900,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: CampusColors.slate900),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CampusCompanionTheme.light.cardRadius)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        selectedColor: CampusColors.brandSoft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: const BorderSide(color: CampusColors.slate200),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: CampusColors.brandSoft,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? CampusColors.brand : CampusColors.slate500,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? CampusColors.brandDeep : CampusColors.slate500,
          ),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.dark(
      primary: CampusColors.brandLight,
      onPrimary: CampusColors.brandDeep,
      primaryContainer: const Color(0xFF1B3A24),
      onPrimaryContainer: CampusColors.brandSoft,
      secondary: CampusColors.slate400,
      onSecondary: CampusColors.slate900,
      secondaryContainer: CampusColors.slate700,
      onSecondaryContainer: CampusColors.slate200,
      tertiary: CampusColors.brandLight,
      onTertiary: CampusColors.slate900,
      surface: CampusColors.slate800,
      onSurface: CampusColors.slate50,
      surfaceContainerHighest: CampusColors.slate700,
      onSurfaceVariant: CampusColors.slate400,
      outline: CampusColors.slate600,
      outlineVariant: CampusColors.slate700,
      error: const Color(0xFFF2B8B5),
      onError: const Color(0xFF601410),
    );
    final base = ThemeData(useMaterial3: true, colorScheme: colorScheme);

    return base.copyWith(
      scaffoldBackgroundColor: CampusColors.slate900,
      textTheme: _textTheme(base.textTheme, CampusColors.slate50),
      extensions: const [CampusCompanionTheme.dark],
      appBarTheme: const AppBarTheme(
        backgroundColor: CampusColors.slate900,
        foregroundColor: CampusColors.slate50,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: CampusColors.slate800,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CampusCompanionTheme.dark.cardRadius)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: CampusColors.slate800,
        indicatorColor: colorScheme.primaryContainer,
      ),
    );
  }
}
