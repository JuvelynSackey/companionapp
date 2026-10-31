import 'package:flutter/material.dart';

/// Campus Companion Design System — slate neutrals with one brand green,
/// the same green as the Welcome/Login screens (LandingColors), so the app
/// reads as one product before and after sign-in. Institution branding is a
/// secondary accent (badges, chips, the Digital ID card), not the primary
/// color scheme.
class CampusColors {
  CampusColors._();

  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155);
  static const slate800 = Color(0xFF1E293B);
  static const slate900 = Color(0xFF0F172A);

  static const brand = Color(0xFF2E7D32);
  static const brandDeep = Color(0xFF0B2E13);
  /// Lighter brand tint, readable on dark backgrounds.
  static const brandLight = Color(0xFF81C784);
  static const brandSoft = Color(0xFFE8F5E9);
  static const canvas = Color(0xFFF4F7F4);

  static const error = Color(0xFFDC2626);
}

@immutable
class CampusCompanionTheme extends ThemeExtension<CampusCompanionTheme> {
  const CampusCompanionTheme({
    required this.cardBackground,
    required this.accentGlow,
    required this.textMuted,
    this.cardRadius = 24.0,
    this.innerRadius = 14.0,
    this.subtleBorder = const Color(0x1FFFFFFF),
  });

  final Color cardBackground;
  final Color accentGlow;
  final Color textMuted;
  final double cardRadius;
  final double innerRadius;
  final Color subtleBorder;

  static const dark = CampusCompanionTheme(
    cardBackground: CampusColors.slate800,
    accentGlow: CampusColors.brandLight,
    textMuted: CampusColors.slate400,
    subtleBorder: Color(0x1FFFFFFF), // ~12% white
  );

  static const light = CampusCompanionTheme(
    cardBackground: Colors.white,
    accentGlow: CampusColors.brand,
    textMuted: CampusColors.slate500,
    subtleBorder: Color(0x14000000), // ~8% black
  );

  BoxDecoration cardDecoration({bool glow = false}) => BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: subtleBorder, width: 1),
        boxShadow: glow
            ? [BoxShadow(color: accentGlow.withValues(alpha: 0.35), blurRadius: 20, spreadRadius: 1)]
            : null,
      );

  /// Shared "slate card" input style — filled with cardBackground, no
  /// visible border until focused (then cyan), used across auth/onboarding
  /// and search fields. Pass [hint] instead of [label] for search-style
  /// fields (a persistent floating label reads oddly on a search box).
  InputDecoration inputDecoration({String? label, String? hint, IconData? icon}) => InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        filled: true,
        fillColor: cardBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(innerRadius), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(innerRadius),
          borderSide: BorderSide(color: subtleBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(innerRadius),
          borderSide: BorderSide(color: accentGlow, width: 2),
        ),
      );

  /// Shared large-radius primary action button shape (24px+ per the design system).
  ButtonStyle get primaryButtonStyle => FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      );

  @override
  CampusCompanionTheme copyWith({
    Color? cardBackground,
    Color? accentGlow,
    Color? textMuted,
    double? cardRadius,
    double? innerRadius,
    Color? subtleBorder,
  }) {
    return CampusCompanionTheme(
      cardBackground: cardBackground ?? this.cardBackground,
      accentGlow: accentGlow ?? this.accentGlow,
      textMuted: textMuted ?? this.textMuted,
      cardRadius: cardRadius ?? this.cardRadius,
      innerRadius: innerRadius ?? this.innerRadius,
      subtleBorder: subtleBorder ?? this.subtleBorder,
    );
  }

  @override
  CampusCompanionTheme lerp(ThemeExtension<CampusCompanionTheme>? other, double t) {
    if (other is! CampusCompanionTheme) return this;
    return CampusCompanionTheme(
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      accentGlow: Color.lerp(accentGlow, other.accentGlow, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      cardRadius: cardRadius + (other.cardRadius - cardRadius) * t,
      innerRadius: innerRadius + (other.innerRadius - innerRadius) * t,
      subtleBorder: Color.lerp(subtleBorder, other.subtleBorder, t)!,
    );
  }
}

/// Convenience accessor: Theme.of(context).campusTheme
extension CampusCompanionThemeGetter on ThemeData {
  CampusCompanionTheme get campusTheme => extension<CampusCompanionTheme>() ?? CampusCompanionTheme.light;
}
