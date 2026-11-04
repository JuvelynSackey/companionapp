import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:mobile/data/models/campus_location.dart';
import 'package:mobile/features/locations/map/street_campus_map_view.dart';

CampusLocation _loc(int id, double lat, double lng, {String category = 'library'}) => CampusLocation(
      locationId: id,
      name: 'Place $id',
      category: category,
      description: '',
      latitude: lat,
      longitude: lng,
    );

void main() {
  test('the map uses OpenFreeMap, which needs no API key', () {
    expect(openFreeMapStyle, 'https://tiles.openfreemap.org/styles/liberty');
    expect(openFreeMapStyle, isNot(contains('key=')));
  });

  group('campusMapBounds', () {
    test('holds every location', () {
      final b = campusMapBounds([_loc(1, 5.650, -0.187), _loc(2, 5.655, -0.183), _loc(3, 5.648, -0.190)]);
      expect(b.southwest, const LatLng(5.648, -0.190));
      expect(b.northeast, const LatLng(5.655, -0.183));
    });

    test('a single location gets a small box around it, not a zero-size one', () {
      final b = campusMapBounds([_loc(1, 5.650, -0.187)]);
      expect(b.northeast.latitude - b.southwest.latitude, closeTo(0.002, 1e-9));
      expect(b.northeast.longitude - b.southwest.longitude, closeTo(0.002, 1e-9));
      expect(campusMapCentre(b).latitude, closeTo(5.650, 1e-9));
      expect(campusMapCentre(b).longitude, closeTo(-0.187, 1e-9));
    });
  });

  test('cssHex gives MapLibre a #RRGGBB colour', () {
    expect(cssHex(const Color(0xFF2196F3)), '#2196F3');
    expect(cssHex(const Color(0x80000A0B)), '#000A0B', reason: 'alpha dropped, leading zeros kept');
  });

  test('a dot sits on the location in its category colour', () {
    final dot = campusDot(_loc(1, 5.650, -0.187, category: 'lecture_hall'));
    expect(dot.geometry, const LatLng(5.650, -0.187));
    expect(dot.circleColor, cssHex(Colors.blue), reason: 'lecture halls are blue in the list and the drawn map');
    expect(dot.circleStrokeColor, '#FFFFFF');
  });

  test('a label shows the name under the dot, in a font OpenFreeMap serves', () {
    final label = campusLabel(_loc(4, 5.650, -0.187));
    expect(label.textField, 'Place 4');
    expect(label.geometry, const LatLng(5.650, -0.187));
    expect(label.textAnchor, 'top');
    expect(label.fontNames, ['Noto Sans Bold']);
  });
}
