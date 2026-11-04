import 'package:flutter/material.dart';
import 'brand_splash.dart';

/// The graduation-cap logo on a cream disc. The art fades into that cream at
/// its edges (see BrandSplash), so on a white screen it needs the disc behind
/// it rather than sitting on white directly.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, required this.size});

  /// Diameter of the disc; the art spans about 80% of it.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Campus Companion logo',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: BrandSplash.background, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Image.asset(BrandSplash.logoAsset, width: size * 0.8, excludeFromSemantics: true),
      ),
    );
  }
}
