import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/campus_companion_theme.dart';
import '../../../data/models/campus_location.dart';
import '../../../widgets/open_in_maps.dart';
import '../category_style.dart';
import 'campus_map_painter.dart';
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
    final campus = Theme.of(context).campusTheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: campus.cardBackground.withValues(alpha: 0.9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: campus.subtleBorder)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: campus.subtleBorder, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: colorForLocationCategory(loc.category).withValues(alpha: 0.15),
                      child: Icon(iconForLocationCategory(loc.category), color: colorForLocationCategory(loc.category)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(loc.name, style: Theme.of(context).textTheme.titleLarge)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorForLocationCategory(loc.category).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    loc.category.replaceAll('_', ' '),
                    style: TextStyle(color: colorForLocationCategory(loc.category), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                if (loc.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(loc.description, style: TextStyle(color: campus.textMuted)),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  style: campus.primaryButtonStyle,
                  onPressed: () => openInMaps(context, label: loc.name, latitude: loc.latitude, longitude: loc.longitude),
                  icon: const Icon(Icons.directions_outlined),
                  label: const Text('Open in Maps'),
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
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
