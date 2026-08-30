import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/campus_location.dart';
import 'package:mobile/features/locations/map/map_coordinate_mapper.dart';

CampusLocation _loc(double lat, double lng) => CampusLocation(
      locationId: 1,
      name: 'Test',
      category: 'other',
      description: '',
      latitude: lat,
      longitude: lng,
    );

void main() {
  const canvasSize = Size(1000, 1000);

  test('a direct mapper places the min corner at bottom-left and max at top-right', () {
    final mapper = MapCoordinateMapper(minLat: 0, maxLat: 10, minLng: 0, maxLng: 10, canvasSize: canvasSize);

    // Lowest latitude -> bottom of the canvas (y = height), since latitude increases northward
    // but screen y increases downward.
    final bottomLeft = mapper.toCanvasOffset(0, 0);
    expect(bottomLeft.dx, closeTo(0, 0.001));
    expect(bottomLeft.dy, closeTo(1000, 0.001));

    final topRight = mapper.toCanvasOffset(10, 10);
    expect(topRight.dx, closeTo(1000, 0.001));
    expect(topRight.dy, closeTo(0, 0.001));
  });

  test('the center of the bounding box maps to the canvas center', () {
    final mapper = MapCoordinateMapper(minLat: 0, maxLat: 10, minLng: 0, maxLng: 10, canvasSize: canvasSize);
    final center = mapper.toCanvasOffset(5, 5);
    expect(center.dx, closeTo(500, 0.001));
    expect(center.dy, closeTo(500, 0.001));
  });

  test('fromLocations computes bounds that contain every location with padding', () {
    final locations = [_loc(5.60, -0.20), _loc(5.65, -0.15), _loc(5.62, -0.18)];
    final mapper = MapCoordinateMapper.fromLocations(locations, canvasSize);

    expect(mapper.minLat, lessThan(5.60));
    expect(mapper.maxLat, greaterThan(5.65));
    expect(mapper.minLng, lessThan(-0.20));
    expect(mapper.maxLng, greaterThan(-0.15));

    // Every real location should project inside the canvas, not clipped to an edge.
    for (final loc in locations) {
      final point = mapper.toCanvasOffset(loc.latitude, loc.longitude);
      expect(point.dx, inInclusiveRange(0, canvasSize.width));
      expect(point.dy, inInclusiveRange(0, canvasSize.height));
    }
  });

  test('a single location does not divide by zero and lands near the canvas center', () {
    final mapper = MapCoordinateMapper.fromLocations([_loc(5.65, -0.18)], canvasSize);
    final point = mapper.toCanvasOffset(5.65, -0.18);
    expect(point.dx.isFinite, isTrue);
    expect(point.dy.isFinite, isTrue);
    expect(point.dx, closeTo(500, 1));
    expect(point.dy, closeTo(500, 1));
  });

  test('an empty location list falls back to a safe default range', () {
    final mapper = MapCoordinateMapper.fromLocations([], canvasSize);
    expect(mapper.minLat, -1);
    expect(mapper.maxLat, 1);
  });
}
