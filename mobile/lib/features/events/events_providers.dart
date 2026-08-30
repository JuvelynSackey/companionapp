import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../data/models/campus_event.dart';

final eventsProvider = FutureProvider.autoDispose<List<CampusEvent>>((ref) {
  return ref.watch(eventApiProvider).fetch();
});
