import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../data/models/schedule_entry.dart';

/// null = show the whole week; 1-7 = Monday..Sunday.
final selectedDayFilterProvider = StateProvider<int?>((ref) => null);

/// Local-only, student-managed — see docs/phase-2-plan.md's timetable
/// architecture note and LocalScheduleRepository. Every mutation
/// best-effort schedules/cancels the matching class reminder; failures
/// (no permission granted yet, or web where the plugin no-ops) are
/// swallowed since a reminder is a nice-to-have, not a save precondition.
class TimetableController extends Notifier<List<ScheduleEntry>> {
  @override
  List<ScheduleEntry> build() => ref.watch(localScheduleRepositoryProvider).getAll();

  Future<void> add({
    required String courseCode,
    required String courseTitle,
    required String lecturer,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? room,
  }) async {
    state = await ref.read(localScheduleRepositoryProvider).add(
          courseCode: courseCode,
          courseTitle: courseTitle,
          lecturer: lecturer,
          dayOfWeek: dayOfWeek,
          startTime: startTime,
          endTime: endTime,
          room: room,
        );
    final added = state.last;
    await _scheduleReminderSilently(added);
  }

  Future<void> update(ScheduleEntry entry) async {
    state = await ref.read(localScheduleRepositoryProvider).update(entry);
    await _scheduleReminderSilently(entry);
  }

  Future<void> delete(int scheduleId) async {
    state = await ref.read(localScheduleRepositoryProvider).delete(scheduleId);
    try {
      await ref.read(notificationServiceProvider).cancelClassReminder(scheduleId);
    } catch (_) {
      // Best-effort — nothing to clean up if it was never scheduled.
    }
  }

  /// Used by the .ics/CSV importer, which assigns its own fresh local ids.
  Future<void> importEntries(List<ScheduleEntry> entries) async {
    state = await ref.read(localScheduleRepositoryProvider).addAll(entries);
    for (final entry in entries) {
      await _scheduleReminderSilently(entry);
    }
  }

  Future<void> _scheduleReminderSilently(ScheduleEntry entry) async {
    try {
      await ref.read(notificationServiceProvider).scheduleClassReminder(entry);
    } catch (_) {
      // No permission yet, or unsupported platform (web) — the explicit
      // "Remind Me" action covers the case where the user wants a bulk
      // permission prompt + reschedule of everything.
    }
  }
}

final timetableControllerProvider = NotifierProvider<TimetableController, List<ScheduleEntry>>(
  TimetableController.new,
);

final filteredScheduleProvider = Provider.autoDispose<List<ScheduleEntry>>((ref) {
  final day = ref.watch(selectedDayFilterProvider);
  final all = ref.watch(timetableControllerProvider);
  // Always build a fresh growable list before sorting in place — `all` can
  // be the Notifier's own state, which is `const []` (immutable) when the
  // local schedule is empty, and sort() throws on an immutable list.
  final filtered = (day == null ? all : all.where((e) => e.dayOfWeek == day)).toList();
  return filtered..sort((a, b) {
    final dayCompare = a.dayOfWeek.compareTo(b.dayOfWeek);
    return dayCompare != 0 ? dayCompare : a.startTime.compareTo(b.startTime);
  });
});
