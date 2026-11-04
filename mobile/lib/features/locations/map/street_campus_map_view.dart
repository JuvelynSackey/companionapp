import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../../data/models/campus_location.dart';
import '../category_style.dart';
import 'campus_map_view.dart';
import 'location_details_sheet.dart';

/// OpenFreeMap's free vector street map (OpenStreetMap data). No API key or
/// account is needed; the style credits OpenFreeMap, OpenMapTiles and
/// OpenStreetMap through MapLibre's attribution button, as their terms ask.
const openFreeMapStyle = 'https://tiles.openfreemap.org/styles/liberty';

/// The campus map on real street tiles (roads, paths, building outlines and
/// names), with each location as a dot in its category colour. Tapping a dot
/// opens the same details sheet as the drawn map. The drawn CampusMapView is
/// one tap away for offline use, since street tiles need a connection.
class StreetCampusMapView extends StatefulWidget {
  const StreetCampusMapView({super.key, required this.locations});
  final List<CampusLocation> locations;

  @override
  State<StreetCampusMapView> createState() => _StreetCampusMapViewState();
}

class _StreetCampusMapViewState extends State<StreetCampusMapView> {
  MapLibreMapController? _controller;
  bool _offline = false;

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
    controller.onCircleTapped.add(_onCircleTapped);
  }

  void _onCircleTapped(Circle circle) {
    final id = circle.data?['locationId'];
    final loc = widget.locations.where((l) => l.locationId == id).firstOrNull;
    if (loc != null && mounted) showLocationDetails(context, loc);
  }

  Future<void> _onStyleLoaded() async {
    final controller = _controller;
    if (controller == null || widget.locations.isEmpty) return;
    await controller.addCircles(
      [for (final loc in widget.locations) campusDot(loc)],
      [for (final loc in widget.locations) {'locationId': loc.locationId}],
    );
    await controller.addSymbols([for (final loc in widget.locations) campusLabel(loc)]);
    await controller.moveCamera(CameraUpdate.newLatLngBounds(
      campusMapBounds(widget.locations),
      left: 48,
      top: 72,
      right: 48,
      bottom: 48,
    ));
  }

  @override
  void dispose() {
    _controller?.onCircleTapped.remove(_onCircleTapped);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.locations.isEmpty) {
      return const Center(child: Text('No locations to show on the map.'));
    }

    final bounds = campusMapBounds(widget.locations);
    return Stack(
      children: [
        if (_offline)
          CampusMapView(locations: widget.locations)
        else
          MapLibreMap(
            styleString: openFreeMapStyle,
            initialCameraPosition: CameraPosition(target: campusMapCentre(bounds), zoom: 15),
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            // A campus map stays north-up and flat, like the drawn one.
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            compassEnabled: false,
          ),
        Positioned(
          top: 12,
          right: 12,
          child: FloatingActionButton.small(
            heroTag: 'campus-map-mode',
            tooltip: _offline ? 'Show street map' : 'Show offline map',
            onPressed: () => setState(() {
              _offline = !_offline;
              if (_offline) _controller = null; // the old map is disposed
            }),
            child: Icon(_offline ? Icons.map_outlined : Icons.cloud_off_outlined),
          ),
        ),
      ],
    );
  }
}

/// The smallest box holding every location. A single location gets a small
/// box around it, since a zero-size box cannot be fitted to the screen.
LatLngBounds campusMapBounds(List<CampusLocation> locations) {
  var south = locations.first.latitude, north = south;
  var west = locations.first.longitude, east = west;
  for (final loc in locations) {
    if (loc.latitude < south) south = loc.latitude;
    if (loc.latitude > north) north = loc.latitude;
    if (loc.longitude < west) west = loc.longitude;
    if (loc.longitude > east) east = loc.longitude;
  }
  const minSpan = 0.002; // about 200 m
  if (north - south < minSpan) {
    final mid = (north + south) / 2;
    south = mid - minSpan / 2;
    north = mid + minSpan / 2;
  }
  if (east - west < minSpan) {
    final mid = (east + west) / 2;
    west = mid - minSpan / 2;
    east = mid + minSpan / 2;
  }
  return LatLngBounds(southwest: LatLng(south, west), northeast: LatLng(north, east));
}

LatLng campusMapCentre(LatLngBounds b) => LatLng(
      (b.southwest.latitude + b.northeast.latitude) / 2,
      (b.southwest.longitude + b.northeast.longitude) / 2,
    );

/// MapLibre takes colours as CSS strings.
String cssHex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// A location's dot: its category colour (as in the list and the drawn map)
/// with a white ring so it stands out on any tile.
CircleOptions campusDot(CampusLocation loc) => CircleOptions(
      geometry: LatLng(loc.latitude, loc.longitude),
      circleRadius: 9,
      circleColor: cssHex(colorForLocationCategory(loc.category)),
      circleStrokeColor: '#FFFFFF',
      circleStrokeWidth: 2.5,
    );

/// The location's name under its dot. Noto Sans is one of the fonts
/// OpenFreeMap serves, so the label renders with the style's own glyphs.
SymbolOptions campusLabel(CampusLocation loc) => SymbolOptions(
      geometry: LatLng(loc.latitude, loc.longitude),
      textField: loc.name,
      fontNames: const ['Noto Sans Bold'],
      textSize: 12,
      textAnchor: 'top',
      textOffset: const Offset(0, 1.1),
      textColor: '#1F2933',
      textHaloColor: '#FFFFFF',
      textHaloWidth: 1.5,
    );
