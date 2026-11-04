import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/campus_companion_theme.dart';
import '../../../data/models/campus_location.dart';
import '../../../widgets/open_in_maps.dart';
import '../category_style.dart';

/// The bottom sheet shown when a location is tapped on either map (the drawn
/// CampusMapView or the GoogleCampusMapView). Completes when it is closed.
Future<void> showLocationDetails(BuildContext context, CampusLocation loc) {
  final campus = Theme.of(context).campusTheme;
  return showModalBottomSheet(
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
  );
}
