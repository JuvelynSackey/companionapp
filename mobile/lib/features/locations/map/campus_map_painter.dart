import 'package:flutter/material.dart';
import '../../../data/models/campus_location.dart';
import '../category_style.dart';
import 'map_coordinate_mapper.dart';

class CampusMapPainter extends CustomPainter {
  CampusMapPainter({
    required this.locations,
    required this.mapper,
    required this.selectedLocationId,
    required this.canvasColor,
    required this.terrainAccent,
    required this.pathColor,
    required this.markerBorderColor,
  });

  final List<CampusLocation> locations;
  final MapCoordinateMapper mapper;
  final int? selectedLocationId;

  /// All theme-derived — no hardcoded light-only palette, so the map
  /// actually follows dark/light mode instead of always rendering a light
  /// canvas regardless of the app's theme.
  final Color canvasColor;
  final Color terrainAccent;
  final Color pathColor;
  final Color markerBorderColor;

  @override
  void paint(Canvas canvas, Size size) {
    _paintTerrain(canvas, size);
    _paintWalkways(canvas, size);
    for (final loc in locations) {
      _paintMarker(canvas, loc, selected: loc.locationId == selectedLocationId);
    }
  }

  void _paintTerrain(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = canvasColor);
    // A couple of soft accent patches for visual texture — decorative only,
    // the backend has no terrain/green-space data to draw from.
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.2), size.shortestSide * 0.12, Paint()..color = terrainAccent);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.8), size.shortestSide * 0.14, Paint()..color = terrainAccent);
  }

  void _paintWalkways(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = pathColor
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.15, size.width * 0.92, size.height * 0.5);
    canvas.drawPath(path, roadPaint);

    final crossPath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.05)
      ..lineTo(size.width * 0.5, size.height * 0.95);
    canvas.drawPath(crossPath, roadPaint..strokeWidth = 6);
  }

  void _paintMarker(Canvas canvas, CampusLocation loc, {required bool selected}) {
    final point = mapper.toCanvasOffset(loc.latitude, loc.longitude);
    final color = colorForLocationCategory(loc.category);

    if (selected) {
      canvas.drawCircle(
        point,
        18,
        Paint()
          ..color = Colors.orange.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    }

    canvas.drawCircle(point, selected ? 12 : 8, Paint()..color = selected ? Colors.orange : color);
    canvas.drawCircle(
      point,
      selected ? 12 : 8,
      Paint()
        ..color = markerBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant CampusMapPainter oldDelegate) {
    return oldDelegate.locations != locations ||
        oldDelegate.selectedLocationId != selectedLocationId ||
        oldDelegate.mapper.canvasSize != mapper.canvasSize ||
        oldDelegate.canvasColor != canvasColor;
  }
}
