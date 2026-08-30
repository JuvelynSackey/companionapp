import 'package:flutter/material.dart';

/// Wraps a ListTile (or similar) in a decorated Container + a properly
/// backed transparent Material, so the rounded corners clip ink splashes
/// correctly.
///
/// Giving `ListTile.shape` a rounded border directly (without an explicit
/// backing Material color) triggers Flutter's "ListTile background color
/// or ink splashes may be invisible" framework exception — the ListTile's
/// own internal Material can't tell what it's being painted over. Wrapping
/// it in an explicit `Material(color: Colors.transparent, ...)` gives it a
/// real (if transparent) color to paint, which is the actual fix; the
/// outer Container's BoxDecoration still supplies the visible
/// background/border/shadow.
class CampusCardTile extends StatelessWidget {
  const CampusCardTile({
    super.key,
    required this.decoration,
    required this.radius,
    required this.child,
    this.margin,
    this.padding,
  });

  final BoxDecoration decoration;
  final double radius;
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
      ),
    );
  }
}
