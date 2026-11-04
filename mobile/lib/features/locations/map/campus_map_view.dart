import 'package:flutter/material.dart';
import '../../../core/theme/campus_companion_theme.dart';
import '../../../data/models/campus_location.dart';
import 'campus_map_painter.dart';
import 'location_details_sheet.dart';
import 'map_coordinate_mapper.dart';

/// Fixed logical canvas size — InteractiveViewer zooms/pans this without
/// changing the coordinate space markers and hit-testing are computed in,
/// so tap tolerance stays consistent at any zoom level.
const _canvasSize = Size(1000, 1000);
const _hitTestTolerance = 26.0;

class CampusMapView extends StatefulWidget {
  const CampusMapView({super.key, required this.locations});
  final List<CampusLocation> locations;

  @override
  State<CampusMapView> createState() => _CampusMapViewState();
}

class _CampusMapViewState extends State<CampusMapView> {
  int? _selectedLocationId;

  CampusLocation? _hitTest(Offset localPosition, MapCoordinateMapper mapper) {
    CampusLocation? closest;
    var closestDistance = double.infinity;
    for (final loc in widget.locations) {
      final point = mapper.toCanvasOffset(loc.latitude, loc.longitude);
      final distance = (point - localPosition).distance;
      if (distance <= _hitTestTolerance && distance < closestDistance) {
        closest = loc;
        closestDistance = distance;
      }
    }
    return closest;
  }

  void _showDetails(CampusLocation loc) {
    setState(() => _selectedLocationId = loc.locationId);
    showLocationDetails(context, loc).whenComplete(() {
      if (mounted) setState(() => _selectedLocationId = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.locations.isEmpty) {
      return const Center(child: Text('No locations to show on the map.'));
    }

    final mapper = MapCoordinateMapper.fromLocations(widget.locations, _canvasSize);
    final theme = Theme.of(context);
    final campus = theme.campusTheme;

    return ClipRect(
      child: InteractiveViewer(
        minScale: 0.6,
        maxScale: 4,
        boundaryMargin: const EdgeInsets.all(80),
        child: GestureDetector(
          onTapUp: (details) {
            final hit = _hitTest(details.localPosition, mapper);
            if (hit != null) _showDetails(hit);
          },
          child: SizedBox(
            width: _canvasSize.width,
            height: _canvasSize.height,
            child: CustomPaint(
              painter: CampusMapPainter(
                locations: widget.locations,
                mapper: mapper,
                selectedLocationId: _selectedLocationId,
                // Theme-derived, not hardcoded — a "deep slate canvas" in
                // dark mode, matching the design system, and the app's
                // signature cyan tint (not an unrelated green) for the
                // decorative terrain texture patches.
                canvasColor: theme.scaffoldBackgroundColor,
                terrainAccent: campus.accentGlow.withValues(alpha: 0.08),
                pathColor: theme.colorScheme.outlineVariant,
                markerBorderColor: campus.cardBackground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
