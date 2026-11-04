import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/event_pass.dart';
import '../../data/models/exam.dart';
import '../../data/models/local_student_profile.dart';
import '../../data/models/resource_models.dart';
import '../../data/models/schedule_entry.dart';
import '../../data/models/student_hub_models.dart';

/// Wraps SharedPreferences for the small bits of local-only state:
/// onboarding/institution selection,
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
  static const _kGuestMode = 'is_guest_mode';
  static const _kReadAnnouncementIds = 'read_announcement_ids';
  static const _kExams = 'local_exams_v1';
  static const _kSchedule = 'local_schedule_v1';
  static const _kNextScheduleId = 'local_schedule_next_id';
  static const _kLocalProfile = 'local_student_profile_v1';
  static const _kEventPasses = 'local_event_passes_v1';
  static const _kRemainingCredits = 'academic_remaining_credits_v1';
  static const _kTargetHonoursTitle = 'academic_target_honours_title_v1';
  static const _kMomoReceipts = 'student_hub_momo_receipts_v1';
  static const _kReportedLostFoundItems = 'student_hub_reported_items_v1';
  static const _kDocumentRequests = 'resources_document_requests_v1';

  String? get selectedInstitutionId => _prefs.getString(_kInstitutionId);
  Future<void> setSelectedInstitutionId(String id) => _prefs.setString(_kInstitutionId, id);

  bool get isOnboardingCompleted => _prefs.getBool(_kOnboardingCompleted) ?? false;
  Future<void> setOnboardingCompleted(bool value) => _prefs.setBool(_kOnboardingCompleted, value);

  /// Whether the last person on this device chose "Continue as Guest" and has
  /// not signed in or left guest mode since.
  bool get isGuestMode => _prefs.getBool(_kGuestMode) ?? false;
  Future<void> setGuestMode(bool value) => _prefs.setBool(_kGuestMode, value);

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

  /// Credits left until graduation, for the Grade Prediction Engine. Null
  /// (not zero) means "not configured yet" — there's no backend or device
  /// source for this, so it must come from the student, and the UI should
  /// prompt for it rather than silently predicting off a guessed number.
  int? get remainingCredits => _prefs.getInt(_kRemainingCredits);
  Future<void> setRemainingCredits(int value) => _prefs.setInt(_kRemainingCredits, value);

  /// The honours class the student is targeting, shared between the
  /// Analytics predictor and the Dashboard snapshot card so they always
  /// agree. Null means not chosen yet.
  String? get targetHonoursTitle => _prefs.getString(_kTargetHonoursTitle);
  Future<void> setTargetHonoursTitle(String title) => _prefs.setString(_kTargetHonoursTitle, title);

  /// Simulated MoMo receipts keyed by due id — see MoMoReceipt's doc comment
  /// on why these are never real payments.
  Map<String, MoMoReceipt> get momoReceipts {
    final raw = _prefs.getString(_kMomoReceipts);
    if (raw == null) return const {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, MoMoReceipt.fromJson(value as Map<String, dynamic>)));
  }

  Future<void> saveMomoReceipts(Map<String, MoMoReceipt> receipts) async {
    final encoded = jsonEncode(receipts.map((key, value) => MapEntry(key, value.toJson())));
    await _prefs.setString(_kMomoReceipts, encoded);
  }

  /// Student-reported lost/found items, layered on top of
  /// StudentHubFixtures.lostFoundSeed() — per-device only, not a shared feed.
  List<LostFoundItem> get reportedLostFoundItems {
    final raw = _prefs.getString(_kReportedLostFoundItems);
    if (raw == null) return const [];
    final decoded = jsonDecode(raw) as List;
    return decoded.map((e) => LostFoundItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveReportedLostFoundItems(List<LostFoundItem> items) async {
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await _prefs.setString(_kReportedLostFoundItems, encoded);
  }

  /// Logged document requests (transcript / proof of registration) — a
  /// request record only, never the document itself. See DocumentType's doc
  /// comment for why.
  List<DocumentRequest> get documentRequests {
    final raw = _prefs.getString(_kDocumentRequests);
    if (raw == null) return const [];
    final decoded = jsonDecode(raw) as List;
    return decoded.map((e) => DocumentRequest.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveDocumentRequests(List<DocumentRequest> requests) async {
    final encoded = jsonEncode(requests.map((e) => e.toJson()).toList());
    await _prefs.setString(_kDocumentRequests, encoded);
  }
}
