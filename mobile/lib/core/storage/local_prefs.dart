import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/event_pass.dart';
import '../../data/models/exam.dart';
import '../../data/models/local_student_profile.dart';
import '../../data/models/schedule_entry.dart';

/// Wraps SharedPreferences for the small bits of local-only state:
/// onboarding/institution selection (mirrors InstitutionPreferencesRepository.kt),
/// per-device announcement read state (not in the backend schema), the
/// local-only Exams feature (no backend table exists for exams), and the
/// now-local-only Schedule/Timetable (student-managed, backend's
/// /api/schedule stays intact but unused — see LocalScheduleRepository).
class LocalPrefs {
  LocalPrefs(this._prefs);

  static Future<LocalPrefs> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalPrefs(prefs);
  }

  final SharedPreferences _prefs;

  static const _kInstitutionId = 'selected_institution_id';
  static const _kOnboardingCompleted = 'is_onboarding_completed';
  static const _kReadAnnouncementIds = 'read_announcement_ids';
  static const _kExams = 'local_exams_v1';
  static const _kSchedule = 'local_schedule_v1';
  static const _kNextScheduleId = 'local_schedule_next_id';
  static const _kLocalProfile = 'local_student_profile_v1';
  static const _kEventPasses = 'local_event_passes_v1';

  String? get selectedInstitutionId => _prefs.getString(_kInstitutionId);
  Future<void> setSelectedInstitutionId(String id) => _prefs.setString(_kInstitutionId, id);

  bool get isOnboardingCompleted => _prefs.getBool(_kOnboardingCompleted) ?? false;
  Future<void> setOnboardingCompleted(bool value) => _prefs.setBool(_kOnboardingCompleted, value);

  Set<int> get readAnnouncementIds =>
      (_prefs.getStringList(_kReadAnnouncementIds) ?? const []).map(int.parse).toSet();

  Future<void> markAnnouncementRead(int id) async {
    final current = readAnnouncementIds..add(id);
    await _prefs.setStringList(_kReadAnnouncementIds, current.map((e) => e.toString()).toList());
  }

  List<Exam> get exams {
    final raw = _prefs.getString(_kExams);
    if (raw == null) return const [];
    final decoded = jsonDecode(raw) as List;
    return decoded.map((e) => Exam.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveExams(List<Exam> exams) async {
    final encoded = jsonEncode(exams.map((e) => e.toJson()).toList());
    await _prefs.setString(_kExams, encoded);
  }

  List<ScheduleEntry> get schedule {
    final raw = _prefs.getString(_kSchedule);
    if (raw == null) return const [];
    final decoded = jsonDecode(raw) as List;
    return decoded.map((e) => ScheduleEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveSchedule(List<ScheduleEntry> schedule) async {
    final encoded = jsonEncode(schedule.map((e) => e.toJson()).toList());
    await _prefs.setString(_kSchedule, encoded);
  }

  /// Monotonic id generator for locally-created schedule entries (used as
  /// both the storage key and the notification id, so it must be a stable int).
  Future<int> nextScheduleId() async {
    final next = (_prefs.getInt(_kNextScheduleId) ?? 0) + 1;
    await _prefs.setInt(_kNextScheduleId, next);
    return next;
  }

  LocalStudentProfile get localStudentProfile {
    final raw = _prefs.getString(_kLocalProfile);
    if (raw == null) return LocalStudentProfile.empty;
    return LocalStudentProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveLocalStudentProfile(LocalStudentProfile profile) =>
      _prefs.setString(_kLocalProfile, jsonEncode(profile.toJson()));

  Map<int, EventPass> get eventPasses {
    final raw = _prefs.getString(_kEventPasses);
    if (raw == null) return const {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(int.parse(key), EventPass.fromJson(value as Map<String, dynamic>)));
  }

  Future<void> saveEventPasses(Map<int, EventPass> passes) async {
    final encoded = jsonEncode(passes.map((key, value) => MapEntry(key.toString(), value.toJson())));
    await _prefs.setString(_kEventPasses, encoded);
  }
}
