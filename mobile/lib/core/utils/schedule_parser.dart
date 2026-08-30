import '../../data/models/schedule_entry.dart';

class ScheduleParseResult {
  const ScheduleParseResult({required this.entries, required this.errors});
  final List<ScheduleEntry> entries;
  final List<String> errors;
}

/// Imports a Timetable that was previously exported by this app — see the
/// migration plan's "round-trip our own export format" scope decision, not
/// general-purpose parsing of arbitrary Google/Outlook/Apple calendar files.
class ScheduleParser {
  ScheduleParser._();

  /// Documented CSV schema (header row required):
  /// courseCode,courseTitle,lecturer,dayOfWeek,startTime,endTime,room
  /// dayOfWeek is 1=Monday..7=Sunday; room may be blank.
  static ScheduleParseResult parseCsv(String content, {required int Function() nextId}) {
    final lines = content.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return const ScheduleParseResult(entries: [], errors: ['File is empty.']);

    final header = lines.first.split(',').map((h) => h.trim().toLowerCase()).toList();
    const expected = ['coursecode', 'coursetitle', 'lecturer', 'dayofweek', 'starttime', 'endtime', 'room'];
    if (!expected.every(header.contains)) {
      return ScheduleParseResult(
        entries: const [],
        errors: ['Header must contain: ${expected.join(', ')}'],
      );
    }

    final entries = <ScheduleEntry>[];
    final errors = <String>[];

    for (var i = 1; i < lines.length; i++) {
      final cells = lines[i].split(',').map((c) => c.trim()).toList();
      if (cells.length < expected.length) {
        errors.add('Row ${i + 1}: expected ${expected.length} columns, got ${cells.length}.');
        continue;
      }
      final row = Map.fromIterables(header, cells);
      final dayOfWeek = int.tryParse(row['dayofweek'] ?? '');
      if (dayOfWeek == null || dayOfWeek < 1 || dayOfWeek > 7) {
        errors.add('Row ${i + 1}: dayOfWeek must be 1-7.');
        continue;
      }
      if (row['coursecode']!.isEmpty || row['starttime']!.isEmpty || row['endtime']!.isEmpty) {
        errors.add('Row ${i + 1}: courseCode, startTime, and endTime are required.');
        continue;
      }

      entries.add(ScheduleEntry.create(
        scheduleId: nextId(),
        courseCode: row['coursecode']!,
        courseTitle: row['coursetitle'] ?? '',
        lecturer: row['lecturer'] ?? '',
        dayOfWeek: dayOfWeek,
        startTime: row['starttime']!,
        endTime: row['endtime']!,
        room: row['room']?.isEmpty ?? true ? null : row['room'],
      ));
    }

    return ScheduleParseResult(entries: entries, errors: errors);
  }

  /// Parses the .ics format produced by IcsExporter.generateScheduleIcs —
  /// SUMMARY:"CODE - Title", DESCRIPTION:"Lecturer: X", LOCATION, and a
  /// DTSTART in "yyyyMMddTHHmmss" local form (day-of-week and start time
  /// are read straight from it).
  static ScheduleParseResult parseIcs(String content, {required int Function() nextId}) {
    final blocks = RegExp(r'BEGIN:VEVENT(.*?)END:VEVENT', dotAll: true).allMatches(content);
    if (blocks.isEmpty) return const ScheduleParseResult(entries: [], errors: ['No VEVENT blocks found.']);

    final entries = <ScheduleEntry>[];
    final errors = <String>[];
    var index = 0;

    for (final block in blocks) {
      index++;
      final text = block.group(1)!;
      final summary = _field(text, 'SUMMARY');
      final description = _field(text, 'DESCRIPTION');
      final location = _field(text, 'LOCATION');
      final dtStart = _field(text, 'DTSTART');
      final dtEnd = _field(text, 'DTEND');

      if (summary == null || dtStart == null || dtEnd == null) {
        errors.add('Event $index: missing SUMMARY/DTSTART/DTEND — skipped.');
        continue;
      }

      final start = _parseIcsDateTime(dtStart);
      final end = _parseIcsDateTime(dtEnd);
      if (start == null || end == null) {
        errors.add('Event $index: could not parse DTSTART/DTEND — skipped.');
        continue;
      }

      final splitIndex = summary.indexOf(' - ');
      final courseCode = splitIndex == -1 ? summary : summary.substring(0, splitIndex);
      final courseTitle = splitIndex == -1 ? '' : summary.substring(splitIndex + 3);
      final lecturer = description?.replaceFirst(RegExp(r'^Lecturer:\s*'), '') ?? '';

      entries.add(ScheduleEntry.create(
        scheduleId: nextId(),
        courseCode: courseCode,
        courseTitle: courseTitle,
        lecturer: lecturer,
        dayOfWeek: start.weekday,
        startTime: _timeOfDay(start),
        endTime: _timeOfDay(end),
        room: (location == null || location == 'TBA') ? null : location,
      ));
    }

    return ScheduleParseResult(entries: entries, errors: errors);
  }

  static String? _field(String block, String name) {
    final match = RegExp('^$name:(.*)\$', multiLine: true).firstMatch(block);
    if (match == null) return null;
    return match.group(1)!.trim().replaceAll(r'\,', ',').replaceAll(r'\;', ';').replaceAll(r'\\', '\\');
  }

  static DateTime? _parseIcsDateTime(String value) {
    // yyyyMMddTHHmmss, optionally with a trailing Z (UTC) which we ignore
    // since our own export always writes local time.
    final match = RegExp(r'^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})').firstMatch(value);
    if (match == null) return null;
    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
    );
  }

  static String _timeOfDay(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
