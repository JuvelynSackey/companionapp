import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../data/models/announcement.dart';

final announcementsProvider = FutureProvider.autoDispose<List<Announcement>>((ref) {
  return ref.watch(announcementApiProvider).fetch();
});
