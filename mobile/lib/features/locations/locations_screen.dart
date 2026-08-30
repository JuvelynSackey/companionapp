import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/campus_companion_theme.dart';
import '../../data/models/campus_location.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/campus_card_tile.dart';
import '../../widgets/open_in_maps.dart';
import 'locations_providers.dart';
import 'map/campus_map_view.dart';

/// Two views over the same GET /api/locations data: a searchable/filterable
/// list, and the interactive CustomPainter campus map using the real
/// lat/long the backend provides (the old app only had percentage-based
/// canvas coordinates, so this is new capability, not a straight port).
class LocationsScreen extends ConsumerWidget {
  const LocationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locations = ref.watch(locationsProvider);
    final categories = ref.watch(locationCategoriesProvider);
    final selectedCategory = ref.watch(locationCategoryFilterProvider);
    final campus = Theme.of(context).campusTheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Campus Locations'),
          bottom: const TabBar(tabs: [Tab(text: 'List'), Tab(text: 'Map')]),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                decoration: campus.inputDecoration(hint: 'Search buildings, libraries, halls...', icon: Icons.search),
                onChanged: (v) => ref.read(locationSearchProvider.notifier).state = v,
              ),
            ),
            categories.when(
              data: (cats) => SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _CategoryChip(
                        label: 'All',
                        selected: selectedCategory == null,
                        onSelected: () => ref.read(locationCategoryFilterProvider.notifier).state = null,
                      ),
                    ),
                    for (final cat in cats)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _CategoryChip(
                          label: cat.replaceAll('_', ' '),
                          selected: selectedCategory == cat,
                          onSelected: () => ref.read(locationCategoryFilterProvider.notifier).state = cat,
                        ),
                      ),
                  ],
                ),
              ),
              loading: () => const SizedBox(height: 40),
              error: (_, _) => const SizedBox(height: 40),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: AsyncValueView<List<CampusLocation>>(
                value: locations,
                onRetry: () => ref.invalidate(locationsProvider),
                data: (context, items) => TabBarView(
                  children: [
                    _LocationsListView(items: items, onRefresh: () => ref.refresh(locationsProvider.future)),
                    CampusMapView(locations: items),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onSelected});
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final campus = Theme.of(context).campusTheme;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      backgroundColor: campus.cardBackground,
      selectedColor: campus.accentGlow.withValues(alpha: 0.18),
      labelStyle: TextStyle(color: selected ? campus.accentGlow : null, fontWeight: selected ? FontWeight.bold : null),
      side: BorderSide(color: selected ? campus.accentGlow : campus.subtleBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(campus.innerRadius)),
    );
  }
}

class _LocationsListView extends StatelessWidget {
  const _LocationsListView({required this.items, required this.onRefresh});
  final List<CampusLocation> items;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        children: const [
          Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No locations found.'))),
        ],
      );
    }
    final campus = Theme.of(context).campusTheme;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final loc = items[index];
          return CampusCardTile(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: campus.cardDecoration(),
            radius: campus.cardRadius,
            child: ListTile(
              leading: CircleAvatar(backgroundColor: campus.accentGlow.withValues(alpha: 0.15), child: Icon(Icons.place_outlined, color: campus.accentGlow)),
              title: Text(loc.name),
              subtitle: Text('${loc.category.replaceAll('_', ' ')}\n${loc.description}', style: TextStyle(color: campus.textMuted)),
              isThreeLine: loc.description.isNotEmpty,
              trailing: IconButton(
                icon: Icon(Icons.directions_outlined, color: campus.accentGlow),
                tooltip: 'Open in Maps',
                onPressed: () => openInMaps(context, label: loc.name, latitude: loc.latitude, longitude: loc.longitude),
              ),
            ),
          );
        },
      ),
    );
  }
}
