import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/ics_exporter.dart';
import 'package:mobile/core/utils/schedule_time_math.dart';
import 'package:mobile/data/models/exam.dart';
import 'package:mobile/data/models/schedule_entry.dart';

void main() {
  group('ScheduleTimeMath', () {
    test('nextOccurrenceOf finds the same day when it is today', () {
      // 2026-08-31 is a Monday.
      final monday = DateTime(2026, 8, 31);
      final result = ScheduleTimeMath.nextOccurrenceOf(1, '09:00', now: monday);
      expect(result, DateTime(2026, 8, 31, 9, 0));
    });

    test('nextOccurrenceOf wraps forward to next week when the day has passed', () {
      // 2026-08-31 is Monday; asking for Sunday (7) should land on 2026-09-06.
      final monday = DateTime(2026, 8, 31);
      final result = ScheduleTimeMath.nextOccurrenceOf(7, '14:00', now: monday);
      expect(result, DateTime(2026, 9, 6, 14, 0));
    });

    test('combine merges a date with an "HH:mm" time string', () {
      final result = ScheduleTimeMath.combine(DateTime(2026, 1, 1), '08:30');
      expect(result, DateTime(2026, 1, 1, 8, 30));
    });
  });

  group('IcsExporter.generateScheduleIcs', () {
    ScheduleEntry entry({int id = 1}) => ScheduleEntry(
          scheduleId: id,
          courseCode: 'DCIT 201',
          courseTitle: 'Mathematics',
          lecturer: 'Prof. A. Mensah',
          dayOfWeek: 2,
          dayName: 'Tuesday',
          startTime: '08:00',
          endTime: '09:30',
          room: 'Room 204',
        );

    test('produces a valid VCALENDAR wrapper with a UID, DTSTART, and DTEND', () {
      final ics = IcsExporter.generateScheduleIcs([entry()], now: DateTime(2026, 8, 31));
      expect(ics, contains('BEGIN:VCALENDAR'));
      expect(ics, contains('END:VCALENDAR'));
      expect(ics, contains('BEGIN:VEVENT'));
      expect(ics, contains('UID:schedule-1@campuscompanion'));
      expect(ics, contains('SUMMARY:DCIT 201 - Mathematics'));
      expect(ics, contains('LOCATION:Room 204'));
      // Must actually carry real date/time data, not just metadata.
      expect(ics, contains('DTSTART:'));
      expect(ics, contains('DTEND:'));
      expect(ics, matches(RegExp(r'DTSTART:\d{8}T\d{6}')));
    });

    test('includes a weekly RRULE since classes recur', () {
      final ics = IcsExporter.generateScheduleIcs([entry()], now: DateTime(2026, 8, 31));
      expect(ics, contains('RRULE:FREQ=WEEKLY;UNTIL='));
    });

    test('falls back to "TBA" when room is null', () {
      final noRoom = ScheduleEntry(
        scheduleId: 2,
        courseCode: 'DCIT 205',
        courseTitle: 'Computer Science',
        lecturer: 'Prof. E. Darko',
        dayOfWeek: 3,
        dayName: 'Wednesday',
        startTime: '11:00',
        endTime: '12:30',
        room: null,
      );
      final ics = IcsExporter.generateScheduleIcs([noRoom], now: DateTime(2026, 8, 31));
      expect(ics, contains('LOCATION:TBA'));
    });

    test('escapes commas in course titles per RFC 5545', () {
      final withComma = ScheduleEntry(
        scheduleId: 3,
        courseCode: 'ENG 101',
        courseTitle: 'Reading, Writing & Composition',
        lecturer: 'Dr. X',
        dayOfWeek: 1,
        dayName: 'Monday',
        startTime: '09:00',
        endTime: '10:00',
        room: 'A1',
      );
      final ics = IcsExporter.generateScheduleIcs([withComma], now: DateTime(2026, 8, 31));
      expect(ics, contains(r'Reading\, Writing & Composition'));
    });
  });

  group('IcsExporter.generateExamsIcs', () {
    test('uses the exam\'s own date, not a recurring rule', () {
      final exam = Exam(
        id: 'e1',
        courseCode: 'DCIT 201',
        courseTitle: 'Mathematics',
        examDate: '2026-09-09',
        startTime: '09:00',
        endTime: '12:00',
        venue: 'Room 204',
        seatRange: 'Index 001-150',
      );
      final ics = IcsExporter.generateExamsIcs([exam], now: DateTime(2026, 8, 31));
      expect(ics, contains('DTSTART:20260909T090000'));
      expect(ics, contains('DTEND:20260909T120000'));
      expect(ics, isNot(contains('RRULE')));
      expect(ics, contains('UID:exam-e1@campuscompanion'));
    });

    test('adds a 1-day-before VALARM', () {
      final exam = Exam(
        id: 'e2',
        courseCode: 'DCIT 202',
        courseTitle: 'Physics',
        examDate: '2026-09-10',
        startTime: '14:00',
        endTime: '17:00',
        venue: 'Great Hall',
      );
      final ics = IcsExporter.generateExamsIcs([exam], now: DateTime(2026, 8, 31));
      expect(ics, contains('BEGIN:VALARM'));
      expect(ics, contains('TRIGGER:-P1D'));
    });
  });
}
