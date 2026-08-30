import 'package:flutter/material.dart';
import 'campus_companion_theme.dart';

/// Campus Companion Design System: a fixed charcoal/slate canvas with a
/// cyan "intelligence accent" as the primary color in both themes.
/// Institution branding no longer drives the primary color scheme (it did
/// in the original ported theme) — it's now a secondary accent applied at
/// specific branding surfaces (institution badge, Digital ID card), not
/// the whole app's chrome. See CampusCompanionTheme for the shared design
/// tokens (card radius, muted text, accent glow) both modes pull from.
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      primary: CampusColors.cyan,
      onPrimary: Colors.white,
      primaryContainer: CampusColors.slate100,
      onPrimaryContainer: CampusColors.slate900,
      secondary: CampusColors.slate600,
      onSecondary: Colors.white,
      secondaryContainer: CampusColors.slate200,
      onSecondaryContainer: CampusColors.slate800,
      tertiary: CampusColors.sky,
      onTertiary: Colors.white,
      surface: Colors.white,
      onSurface: CampusColors.slate900,
      surfaceContainerHighest: CampusColors.slate100,
      onSurfaceVariant: CampusColors.slate500,
      outline: CampusColors.slate300,
      outlineVariant: CampusColors.slate200,
      error: CampusColors.error,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: CampusColors.slate100,
      extensions: const [CampusCompanionTheme.light],
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: CampusColors.slate900,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CampusCompanionTheme.light.cardRadius)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: colorScheme.primaryContainer,
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.dark(
      primary: CampusColors.cyan,
      onPrimary: CampusColors.slate900,
      primaryContainer: const Color(0xFF164E63), // cyan-tinted dark container
      onPrimaryContainer: CampusColors.sky,
      secondary: CampusColors.slate400,
      onSecondary: CampusColors.slate900,
      secondaryContainer: CampusColors.slate700,
      onSecondaryContainer: CampusColors.slate200,
      tertiary: CampusColors.sky,
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

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: CampusColors.slate900,
      extensions: const [CampusCompanionTheme.dark],
      appBarTheme: const AppBarTheme(
        backgroundColor: CampusColors.slate900,
        foregroundColor: CampusColors.slate50,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: CampusColors.slate800,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CampusCompanionTheme.dark.cardRadius)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: CampusColors.slate800,
        indicatorColor: colorScheme.primaryContainer,
      ),
    );
  }
}
