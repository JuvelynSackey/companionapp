import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/engine/context_engine.dart';
import '../../core/providers/core_providers.dart';
import '../../data/models/dashboard_data.dart';
import '../../data/models/exam_countdown.dart';
import '../exams/exams_providers.dart';
import '../locations/locations_providers.dart';
import '../timetable/timetable_providers.dart';

final dashboardProvider = FutureProvider.autoDispose<DashboardData>((ref) {
  return ref.watch(dashboardApiProvider).fetch();
});

/// Backend DashboardData still supplies announcements/upcomingEvents, but
/// its classesToday/todaysClasses fields reflect the (now-unused)
/// /api/schedule table, not the student's local timetable — this provider
/// overrides just those two with locally-computed values.
final dashboardViewProvider = FutureProvider.autoDispose<DashboardData>((ref) async {
  final backend = await ref.watch(dashboardProvider.future);
  final schedule = ref.watch(timetableControllerProvider);

  final now = DateTime.now();
  final todaysClasses = schedule.where((e) => e.dayOfWeek == now.weekday).toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));

  bool isInProgress(String startTime, String endTime) {
    final nowMinutes = now.hour * 60 + now.minute;
    final start = _minutesOf(startTime);
    final end = _minutesOf(endTime);
    return nowMinutes >= start && nowMinutes < end;
  }

  return DashboardData(
    stats: DashboardStats(
      classesToday: todaysClasses.length,
      announcements: backend.stats.announcements,
      upcomingEvents: backend.stats.upcomingEvents,
    ),
    todaysClasses: [
      for (final e in todaysClasses)
        TodayClass(
          scheduleId: e.scheduleId,
          courseTitle: e.courseTitle,
          lecturer: e.lecturer,
          room: e.room,
          startTime: e.startTime,
          endTime: e.endTime,
          inProgress: isInProgress(e.startTime, e.endTime),
        ),
    ],
    announcements: backend.announcements,
    upcomingEvents: backend.upcomingEvents,
  );
});

int _minutesOf(String hhmm) {
  final parts = hhmm.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

/// Feeds the Dashboard's Daily Brief + smart action cards.
final dashboardContextProvider = FutureProvider.autoDispose<List<CampusContextAction>>((ref) async {
  final now = DateTime.now();
  final schedule = ref.watch(timetableControllerProvider);
  final todaysSchedule = schedule.where((e) => e.dayOfWeek == now.weekday).toList();

  final exams = ref.watch(examsControllerProvider);
  final examCountdowns = ExamCountdownUtils.getSortedUpcomingExams(exams, now: now);

  final locations = await ref.watch(allLocationsProvider.future);

  return ContextEngine.evaluate(
    todaysSchedule: todaysSchedule,
    examCountdowns: examCountdowns,
    locations: locations,
    now: now,
  );
});
