import 'package:flutter/material.dart';

/// Colors and shared styling for the pre-sign-in flow only (WelcomeScreen,
/// SignInScreen, SignUpScreen) — a green/light look, deliberately separate
/// from CampusCompanionTheme (the cyan/slate look the rest of the app, past
/// sign-in, uses). Not a ThemeExtension: these are plain constants a handful
/// of widgets reach for directly, not something that needs to lerp across an
/// app-wide light/dark switch.
class LandingColors {
  LandingColors._();

  static const green900 = Color(0xFF0B2E13);
  static const green700 = Color(0xFF1B5E20);
  static const green500 = Color(0xFF2E7D32);
  static const green200 = Color(0xFFA5D6A7);
  static const green100 = Color(0xFFE8F5E9);

  static const ink = Color(0xFF14241A);
  static const inkMuted = Color(0xFF5C6B60);
  static const fieldFill = Color(0xFFF2F6F2);
  static const border = Color(0xFFE1E8E2);

  static const error = Color(0xFFDC2626);
}

/// Shared shapes/paddings so WelcomeScreen, SignInScreen and SignUpScreen
/// look like one flow rather than three separately-tuned screens.
class LandingStyle {
  LandingStyle._();

  static const double buttonRadius = 28;
  static const double fieldRadius = 14;

  static ButtonStyle get primaryButtonStyle => FilledButton.styleFrom(
        backgroundColor: LandingColors.green900,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonRadius)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      );

  static ButtonStyle get outlinedButtonStyle => OutlinedButton.styleFrom(
        backgroundColor: LandingColors.green100,
        foregroundColor: LandingColors.ink,
        disabledForegroundColor: LandingColors.inkMuted,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: LandingColors.green200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonRadius)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      );

  static InputDecoration fieldDecoration({required String label, IconData? icon, Widget? suffixIcon}) =>
      InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: LandingColors.inkMuted) : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: LandingColors.fieldFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(fieldRadius), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: const BorderSide(color: LandingColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: const BorderSide(color: LandingColors.green500, width: 2),
        ),
        labelStyle: const TextStyle(color: LandingColors.inkMuted),
      );
}
