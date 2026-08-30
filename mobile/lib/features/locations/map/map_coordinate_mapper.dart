import 'dart:ui';
import '../../../data/models/campus_location.dart';

/// Projects real lat/long onto a fixed canvas size. Bounds are computed from
/// the actual fetched locations (with padding) rather than a hardcoded
/// campus bounding box — the backend has no official campus-boundary data,
/// just per-location coordinates (seeded for UG Legon, per PROJECT_AUDIT.md).
class MapCoordinateMapper {
  MapCoordinateMapper({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
    required this.canvasSize,
  });

  factory MapCoordinateMapper.fromLocations(List<CampusLocation> locations, Size canvasSize, {double paddingFraction = 0.15}) {
    if (locations.isEmpty) {
      return MapCoordinateMapper(minLat: -1, maxLat: 1, minLng: -1, maxLng: 1, canvasSize: canvasSize);
    }

    var minLat = locations.first.latitude;
    var maxLat = locations.first.latitude;
    var minLng = locations.first.longitude;
    var maxLng = locations.first.longitude;

    for (final loc in locations) {
      if (loc.latitude < minLat) minLat = loc.latitude;
      if (loc.latitude > maxLat) maxLat = loc.latitude;
      if (loc.longitude < minLng) minLng = loc.longitude;
      if (loc.longitude > maxLng) maxLng = loc.longitude;
    }

    // A single-point or degenerate bounding box would divide by zero below,
    // and cramming every marker onto one campus edge looks broken even for
    // 2+ closely-clustered points — pad every side by a fraction of the span.
    final latSpan = (maxLat - minLat).abs() < 0.0001 ? 0.01 : (maxLat - minLat);
    final lngSpan = (maxLng - minLng).abs() < 0.0001 ? 0.01 : (maxLng - minLng);
    final latPad = latSpan * paddingFraction;
    final lngPad = lngSpan * paddingFraction;

    return MapCoordinateMapper(
      minLat: minLat - latPad,
      maxLat: maxLat + latPad,
      minLng: minLng - lngPad,
      maxLng: maxLng + lngPad,
      canvasSize: canvasSize,
    );
  }

  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;
  final Size canvasSize;

  Offset toCanvasOffset(double lat, double lng) {
    final x = ((lng - minLng) / (maxLng - minLng)) * canvasSize.width;
    // Invert Y: screen coordinates originate top-left, latitude increases northward.
    final y = (1.0 - ((lat - minLat) / (maxLat - minLat))) * canvasSize.height;
    return Offset(x, y);
  }
}
