/// Shared by IcsExporter and NotificationService — both need to turn a
/// recurring ScheduleEntry's (dayOfWeek, "HH:mm") into an actual DateTime.
class ScheduleTimeMath {
  ScheduleTimeMath._();

  /// The next date (today or later) that falls on [dayOfWeek] (1=Monday..7=Sunday),
  /// combined with [timeOfDay] ("HH:mm"). If [dayOfWeek] is today but
  /// [timeOfDay] has already passed, still returns today (matches the
  /// source app's semantics — "next occurrence" callers that need to skip
  /// an already-passed today should check the result against `now` themselves).
  static DateTime nextOccurrenceOf(int dayOfWeek, String timeOfDay, {DateTime? now}) {
    final today = now ?? DateTime.now();
    var daysAhead = dayOfWeek - today.weekday;
    if (daysAhead < 0) daysAhead += 7;
    final date = DateTime(today.year, today.month, today.day).add(Duration(days: daysAhead));
    return combine(date, timeOfDay);
  }

  static DateTime combine(DateTime date, String timeOfDay) {
    final parts = timeOfDay.split(':');
    return DateTime(date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1]));
  }
}
