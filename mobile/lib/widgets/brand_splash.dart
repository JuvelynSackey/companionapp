import 'package:flutter/material.dart';
import '../core/theme/landing_theme.dart';

/// Shown at launch while the saved session is checked. It continues the
/// native launch screen (android/app/src/main/res/drawable/launch_background.xml,
/// web/index.html): same cream, same 200-wide logo at the same centre, so the
/// hand-off is seamless; only the app name fades in underneath. It is never
/// held on screen artificially: it lasts exactly as long as the restore.
class BrandSplash extends StatelessWidget {
  const BrandSplash({super.key});

  /// The flat cream behind the logo art; the native splash and the launcher
  /// icon use the same value (colors.xml, web/manifest.json).
  static const background = Color(0xFFFCF6E4);
  static const logoAsset = 'assets/brand/logo.png';
  static const logoWidth = 200.0;

  @override
  Widget build(BuildContext context) {
    // The asset is 720 x 474 (art plus its feathered margin).
    const logoHeight = logoWidth * 474 / 720;
    return Semantics(
      label: 'Campus Companion is loading',
      child: ColoredBox(
        color: background,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(child: Image.asset(logoAsset, width: logoWidth, excludeFromSemantics: true)),
            Center(
              child: Transform.translate(
                offset: const Offset(0, logoHeight / 2 + 28),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  builder: (context, t, child) => Opacity(
                    opacity: t,
                    child: Transform.translate(offset: Offset(0, 8 * (1 - t)), child: child),
                  ),
                  child: const ExcludeSemantics(
                    child: Text(
                      'Campus Companion',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: LandingColors.ink,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
