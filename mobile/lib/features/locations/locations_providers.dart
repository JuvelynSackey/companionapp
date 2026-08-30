import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../data/models/campus_location.dart';

final locationCategoryFilterProvider = StateProvider<String?>((ref) => null);
final locationSearchProvider = StateProvider<String>((ref) => '');

final locationCategoriesProvider = FutureProvider.autoDispose<List<String>>((ref) {
  return ref.watch(locationApiProvider).fetchCategories();
});

final locationsProvider = FutureProvider.autoDispose<List<CampusLocation>>((ref) {
  final category = ref.watch(locationCategoryFilterProvider);
  final search = ref.watch(locationSearchProvider);
  return ref.watch(locationApiProvider).fetch(category: category, search: search);
});

/// Unfiltered, independent of whatever category/search is set on the
/// Locations screen — for consumers (AI assistant context, dashboard
/// context engine) that want the full campus list regardless of UI filter state.
final allLocationsProvider = FutureProvider.autoDispose<List<CampusLocation>>((ref) {
  return ref.watch(locationApiProvider).fetch();
});
