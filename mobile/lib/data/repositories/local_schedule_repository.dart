import '../../core/storage/local_prefs.dart';
import '../models/schedule_entry.dart';

/// Local-only CRUD — the Timetable is now fully student-managed (see the
/// migration plan's "user-uploaded timetable" decision). The backend's
/// GET/POST/DELETE /api/schedule stays intact and working, but unused,
/// kept available as a possible future cloud-backup layer.
class LocalScheduleRepository {
  LocalScheduleRepository(this._prefs);
  final LocalPrefs _prefs;

  List<ScheduleEntry> getAll() => _prefs.schedule;

  Future<List<ScheduleEntry>> add({
    required String courseCode,
    required String courseTitle,
    required String lecturer,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? room,
  }) async {
    final id = await _prefs.nextScheduleId();
    final entry = ScheduleEntry.create(
      scheduleId: id,
      courseCode: courseCode,
      courseTitle: courseTitle,
      lecturer: lecturer,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      room: room,
    );
    final all = [..._prefs.schedule, entry];
    await _prefs.saveSchedule(all);
    return all;
  }

  /// Appends entries that already carry their own ids (e.g. from a parsed
  /// import file) without going through nextScheduleId() — the importer
  /// assigns fresh local ids itself so it can report a count up front.
  Future<List<ScheduleEntry>> addAll(List<ScheduleEntry> entries) async {
    final all = [..._prefs.schedule, ...entries];
    await _prefs.saveSchedule(all);
    return all;
  }

  Future<List<ScheduleEntry>> update(ScheduleEntry entry) async {
    final all = _prefs.schedule.map((e) => e.scheduleId == entry.scheduleId ? entry : e).toList();
    await _prefs.saveSchedule(all);
    return all;
  }

  Future<List<ScheduleEntry>> delete(int scheduleId) async {
    final all = _prefs.schedule.where((e) => e.scheduleId != scheduleId).toList();
    await _prefs.saveSchedule(all);
    return all;
  }

  Future<int> nextId() => _prefs.nextScheduleId();
}
