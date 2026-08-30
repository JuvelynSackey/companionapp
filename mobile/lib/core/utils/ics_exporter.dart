import '../../data/models/exam.dart';
import '../../data/models/schedule_entry.dart';
import 'schedule_time_math.dart';

/// RFC 5545 iCalendar generation. The draft this was scoped from omitted
/// DTSTART/DTEND/UID entirely, which would produce a .ics file with no
/// actual date/time data — every field here exists because a real calendar
/// app needs it to import the event at all.
class IcsExporter {
  IcsExporter._();

  static const _semesterWeeksCount = 15;

  /// Weekly-recurring VEVENTs (RRULE) for a class timetable, one per
  /// ScheduleEntry. Each entry only carries a day-of-week + time-of-day
  /// (no absolute date), so DTSTART is computed as the next upcoming
  /// occurrence of that weekday.
  static String generateScheduleIcs(List<ScheduleEntry> entries, {DateTime? now}) {
    final buffer = StringBuffer();
    _writeHeader(buffer);

    for (final entry in entries) {
      final start = ScheduleTimeMath.nextOccurrenceOf(entry.dayOfWeek, entry.startTime, now: now);
      final end = ScheduleTimeMath.combine(start, entry.endTime);
      final until = start.add(Duration(days: 7 * _semesterWeeksCount));

      buffer.writeln('BEGIN:VEVENT');
      buffer.writeln('UID:schedule-${entry.scheduleId}@campuscompanion');
      buffer.writeln('DTSTAMP:${_formatUtc(now ?? DateTime.now())}');
      buffer.writeln('DTSTART:${_formatLocal(start)}');
      buffer.writeln('DTEND:${_formatLocal(end)}');
      buffer.writeln('RRULE:FREQ=WEEKLY;UNTIL=${_formatLocal(until)}');
      buffer.writeln('SUMMARY:${_escape('${entry.courseCode} - ${entry.courseTitle}')}');
      buffer.writeln('DESCRIPTION:${_escape('Lecturer: ${entry.lecturer}')}');
      buffer.writeln('LOCATION:${_escape(entry.room ?? 'TBA')}');
      buffer.writeln('END:VEVENT');
    }

    buffer.writeln('END:VCALENDAR');
    return buffer.toString();
  }

  /// One-off VEVENTs for exams, using each exam's own date (no recurrence).
  static String generateExamsIcs(List<Exam> exams, {DateTime? now}) {
    final buffer = StringBuffer();
    _writeHeader(buffer);

    for (final exam in exams) {
      final date = DateTime.parse(exam.examDate);
      final start = ScheduleTimeMath.combine(date, exam.startTime);
      final end = ScheduleTimeMath.combine(date, exam.endTime);

      buffer.writeln('BEGIN:VEVENT');
      buffer.writeln('UID:exam-${exam.id}@campuscompanion');
      buffer.writeln('DTSTAMP:${_formatUtc(now ?? DateTime.now())}');
      buffer.writeln('DTSTART:${_formatLocal(start)}');
      buffer.writeln('DTEND:${_formatLocal(end)}');
      buffer.writeln('SUMMARY:${_escape('Exam: ${exam.courseCode} - ${exam.courseTitle}')}');
      buffer.writeln('DESCRIPTION:${_escape(exam.rules.isNotEmpty ? exam.rules : 'Seat range: ${exam.seatRange}')}');
      buffer.writeln('LOCATION:${_escape(exam.venue)}');
      buffer.writeln('BEGIN:VALARM');
      buffer.writeln('ACTION:DISPLAY');
      buffer.writeln('DESCRIPTION:Exam reminder');
      buffer.writeln('TRIGGER:-P1D'); // 1 day before
      buffer.writeln('END:VALARM');
      buffer.writeln('END:VEVENT');
    }

    buffer.writeln('END:VCALENDAR');
    return buffer.toString();
  }

  static void _writeHeader(StringBuffer buffer) {
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//Campus Companion//EN');
    buffer.writeln('CALSCALE:GREGORIAN');
  }

  static String _formatLocal(DateTime dt) {
    String pad2(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}${pad2(dt.month)}${pad2(dt.day)}T${pad2(dt.hour)}${pad2(dt.minute)}00';
  }

  static String _formatUtc(DateTime dt) {
    final utc = dt.toUtc();
    String pad2(int n) => n.toString().padLeft(2, '0');
    return '${utc.year}${pad2(utc.month)}${pad2(utc.day)}T${pad2(utc.hour)}${pad2(utc.minute)}${pad2(utc.second)}Z';
  }

  /// Escapes commas, semicolons, backslashes and newlines per RFC 5545 §3.3.11.
  static String _escape(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll(',', '\\,')
        .replaceAll(';', '\\;')
        .replaceAll('\n', '\\n');
  }
}
