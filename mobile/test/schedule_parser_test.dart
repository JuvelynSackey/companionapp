import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/ics_exporter.dart';
import 'package:mobile/core/utils/schedule_parser.dart';
import 'package:mobile/data/models/schedule_entry.dart';

void main() {
  group('ScheduleParser.parseIcs', () {
    test('round-trips an .ics file this app exported', () {
      final original = [
        ScheduleEntry.create(
          scheduleId: 1,
          courseCode: 'DCIT 201',
          courseTitle: 'Mathematics',
          lecturer: 'Prof. A. Mensah',
          dayOfWeek: 2,
          startTime: '08:00',
          endTime: '09:30',
          room: 'Room 204',
        ),
      ];
      final ics = IcsExporter.generateScheduleIcs(original, now: DateTime(2026, 8, 31));

      var id = 100;
      final result = ScheduleParser.parseIcs(ics, nextId: () => id++);

      expect(result.errors, isEmpty);
      expect(result.entries, hasLength(1));
      final parsed = result.entries.first;
      expect(parsed.courseCode, 'DCIT 201');
      expect(parsed.courseTitle, 'Mathematics');
      expect(parsed.lecturer, 'Prof. A. Mensah');
      expect(parsed.dayOfWeek, 2);
      expect(parsed.startTime, '08:00');
      expect(parsed.endTime, '09:30');
      expect(parsed.room, 'Room 204');
    });

    test('round-trips a course title containing an escaped comma', () {
      final original = [
        ScheduleEntry.create(
          scheduleId: 2,
          courseCode: 'ENG 101',
          courseTitle: 'Reading, Writing & Composition',
          lecturer: 'Dr. X',
          dayOfWeek: 1,
          startTime: '09:00',
          endTime: '10:00',
          room: 'A1',
        ),
      ];
      final ics = IcsExporter.generateScheduleIcs(original, now: DateTime(2026, 8, 31));
      final result = ScheduleParser.parseIcs(ics, nextId: () => 1);

      expect(result.entries.single.courseTitle, 'Reading, Writing & Composition');
    });

    test('maps a null room ("TBA" in the export) back to null', () {
      final original = [
        ScheduleEntry.create(
          scheduleId: 3,
          courseCode: 'DCIT 205',
          courseTitle: 'Computer Science',
          lecturer: 'Prof. E. Darko',
          dayOfWeek: 3,
          startTime: '11:00',
          endTime: '12:30',
          room: null,
        ),
      ];
      final ics = IcsExporter.generateScheduleIcs(original, now: DateTime(2026, 8, 31));
      final result = ScheduleParser.parseIcs(ics, nextId: () => 1);

      expect(result.entries.single.room, isNull);
    });

    test('reports an error for content with no VEVENT blocks instead of crashing', () {
      final result = ScheduleParser.parseIcs('BEGIN:VCALENDAR\nEND:VCALENDAR', nextId: () => 1);
      expect(result.entries, isEmpty);
      expect(result.errors, isNotEmpty);
    });
  });

  group('ScheduleParser.parseCsv', () {
    const validCsv = 'courseCode,courseTitle,lecturer,dayOfWeek,startTime,endTime,room\n'
        'DCIT 201,Mathematics,Prof. A. Mensah,2,08:00,09:30,Room 204\n'
        'DCIT 205,Computer Science,Prof. E. Darko,3,11:00,12:30,';

    test('parses valid rows, treating a blank room cell as null', () {
      final result = ScheduleParser.parseCsv(validCsv, nextId: () => 1);
      expect(result.errors, isEmpty);
      expect(result.entries, hasLength(2));
      expect(result.entries[0].room, 'Room 204');
      expect(result.entries[1].room, isNull);
    });

    test('rejects a file with a missing required header column', () {
      const badHeader = 'courseCode,courseTitle,dayOfWeek,startTime,endTime,room\nDCIT 201,Math,2,08:00,09:30,A1';
      final result = ScheduleParser.parseCsv(badHeader, nextId: () => 1);
      expect(result.entries, isEmpty);
      expect(result.errors, isNotEmpty);
    });

    test('collects a per-row error for an out-of-range dayOfWeek without aborting the whole import', () {
      const mixedCsv = 'courseCode,courseTitle,lecturer,dayOfWeek,startTime,endTime,room\n'
          'DCIT 201,Mathematics,Prof. A,9,08:00,09:30,A1\n'
          'DCIT 205,Computer Science,Prof. B,3,11:00,12:30,B2';
      final result = ScheduleParser.parseCsv(mixedCsv, nextId: () => 1);
      expect(result.entries, hasLength(1));
      expect(result.entries.single.courseCode, 'DCIT 205');
      expect(result.errors, hasLength(1));
    });
  });
}
