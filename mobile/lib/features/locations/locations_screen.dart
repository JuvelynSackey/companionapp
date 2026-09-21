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
class LocationsScreen extends ConsumerStatefulWidget {
  const LocationsScreen({super.key});

  @override
  ConsumerState<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends ConsumerState<LocationsScreen> {
  // Bound to locationSearchProvider's current value so the visible text
  // can't desync from the actual filter — an uncontrolled TextField would
  // reset to empty on rebuild while the provider (and thus the filtered
  // list) silently kept the last-typed search term.
  late final _searchController = TextEditingController(text: ref.read(locationSearchProvider));

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locations = ref.watch(locationsProvider);
    final categories = ref.watch(locationCategoriesProvider);
    final selectedCategory = ref.watch(locationCategoryFilterProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Campus Locations'),
          bottom: const TabBar(tabs: [Tab(text: 'List'), Tab(text: 'Map')]),
        ),
        body: AsyncValueView<List<CampusLocation>>(
          value: locations,
          onRetry: () => ref.invalidate(locationsProvider),
          data: (context, items) => TabBarView(
            children: [
              // Search + category header lives inside this tab's own
              // CustomScrollView (not a fixed Column above the TabBarView)
              // so the whole thing scrolls instead of overflowing when
              // there's little vertical room left — e.g. landscape with
              // the keyboard open, where the header alone can exceed the
              // space remaining above the keyboard.
              _LocationsListView(
                searchController: _searchController,
                categories: categories,
                selectedCategory: selectedCategory,
                items: items,
                onRefresh: () => ref.refresh(locationsProvider.future),
              ),
              CampusMapView(locations: items),
            ],
          ),
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

class _LocationsListView extends ConsumerWidget {
  const _LocationsListView({
    required this.searchController,
    required this.categories,
    required this.selectedCategory,
    required this.items,
    required this.onRefresh,
  });

  final TextEditingController searchController;
  final AsyncValue<List<String>> categories;
  final String? selectedCategory;
  final List<CampusLocation> items;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campus = Theme.of(context).campusTheme;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        // Search field + category chips are slivers in the same scroll
        // view as the list, not a fixed Column above it — so the whole
        // screen scrolls instead of overflowing when there isn't enough
        // height for the header alone (e.g. landscape with the keyboard open).
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: searchController,
                decoration: campus.inputDecoration(hint: 'Search buildings, libraries, halls...', icon: Icons.search),
                onChanged: (v) => ref.read(locationSearchProvider.notifier).state = v,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: categories.when(
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
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 4)),
          if (items.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No locations found.'))),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.builder(
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
            ),
        ],
      ),
    );
  }
}
