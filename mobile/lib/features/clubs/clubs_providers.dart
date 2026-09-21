import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/core_providers.dart';
import '../../data/models/campus_event.dart';
import '../../data/models/club.dart';
import '../events/events_providers.dart';

/// Club ids with a join/leave request currently in flight. Not autoDispose:
/// it only holds ids and is always cleared in a finally block.
final clubMembershipPendingProvider = StateProvider<Set<int>>((ref) => const {});

final clubsProvider =
    AsyncNotifierProvider.autoDispose<ClubsController, List<Club>>(ClubsController.new);

class ClubsController extends AutoDisposeAsyncNotifier<List<Club>> {
  @override
  Future<List<Club>> build() => ref.watch(clubApiProvider).fetch();

  /// Joins or leaves [clubId], flipping the UI immediately and rolling that
  /// one club back if the request fails (the error is rethrown so the caller
  /// can tell the student). Ignored while a request for the same club is
  /// already in flight, so a double tap cannot fire two requests.
  Future<void> toggleMembership(int clubId) async {
    final clubs = state.valueOrNull;
    if (clubs == null) return;

    final index = clubs.indexWhere((c) => c.clubId == clubId);
    if (index == -1) return;

    final pending = ref.read(clubMembershipPendingProvider);
    if (pending.contains(clubId)) return;

    final original = clubs[index];
    final wasMember = original.isMember;
    final api = ref.read(clubApiProvider);

    // Keep the provider alive if the student leaves the screen mid-request;
    // otherwise writing state afterwards would hit a disposed provider.
    final link = ref.keepAlive();
    ref.read(clubMembershipPendingProvider.notifier).state = {...pending, clubId};
    _replace(original.toggledMembership());

    try {
      if (wasMember) {
        await api.leave(clubId);
      } else {
        await api.join(clubId);
      }
    } catch (e) {
      if (wasMember && e is ApiException && e.statusCode == 404) {
        // The server says we were not a member, which is where the optimistic
        // update already put us. Only the member count may be stale.
        ref.invalidateSelf();
        return;
      }
      _replace(original);
      rethrow;
    } finally {
      final remaining = {...ref.read(clubMembershipPendingProvider)}..remove(clubId);
      ref.read(clubMembershipPendingProvider.notifier).state = remaining;
      link.close();
    }
  }

  /// Swaps one club in the current list without touching the others, so
  /// concurrent toggles on different clubs cannot undo each other.
  void _replace(Club club) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData([for (final c in current) c.clubId == club.clubId ? club : c]);
  }
}

enum ClubFilter { all, mine }

final clubSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');
final clubFilterProvider = StateProvider.autoDispose<ClubFilter>((ref) => ClubFilter.all);

/// The club list narrowed by the search box and the All / My clubs chips.
final filteredClubsProvider = Provider.autoDispose<AsyncValue<List<Club>>>((ref) {
  final query = ref.watch(clubSearchQueryProvider).trim().toLowerCase();
  final filter = ref.watch(clubFilterProvider);

  return ref.watch(clubsProvider).whenData((clubs) => clubs.where((club) {
        if (filter == ClubFilter.mine && !club.isMember) return false;
        if (query.isEmpty) return true;
        return club.name.toLowerCase().contains(query) || club.description.toLowerCase().contains(query);
      }).toList());
});

/// Reads one club out of the shared list so the detail screen reflects
/// optimistic joins made anywhere.
final clubByIdProvider = Provider.autoDispose.family<Club?, int>((ref, clubId) {
  final clubs = ref.watch(clubsProvider).valueOrNull;
  if (clubs == null) return null;
  for (final club in clubs) {
    if (club.clubId == clubId) return club;
  }
  return null;
});

/// Upcoming events organised by a club. The events endpoint reports the
/// organiser by name only (club names are unique), so that is what we match on.
final clubEventsProvider =
    Provider.autoDispose.family<AsyncValue<List<CampusEvent>>, String>((ref, clubName) {
  return ref.watch(eventsProvider).whenData(
        (events) => events.where((e) => e.clubName == clubName).toList(),
      );
});
