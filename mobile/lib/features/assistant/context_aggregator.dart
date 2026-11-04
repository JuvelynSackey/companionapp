import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/logic/academic_engine.dart';
import '../../data/models/announcement.dart';
import '../../data/models/campus_event.dart';
import '../../data/models/campus_location.dart';
import '../../data/models/course_grade.dart';
import '../../data/models/dashboard_data.dart';
import '../../data/models/exam_countdown.dart';
import '../../data/models/institution_profile.dart';
import '../alerts/alerts_providers.dart';
import '../analytics/analytics_providers.dart';
import '../auth/session_controller.dart';
import '../dashboard/dashboard_providers.dart';
import '../events/events_providers.dart';
import '../exams/exams_providers.dart';
import '../locations/locations_providers.dart';
import '../onboarding/institution_controller.dart';

/// The parts of [AssistantContext] that come from the server. Any of them can
/// be unavailable (offline, backend asleep) without the rest being affected.
enum ContextSource {
  grades('grades'),
  events('events'),
  announcements('alerts'),
  locations('campus locations');

  const ContextSource(this.label);
  final String label;
}

/// Everything the assistant (Gemini prompt or local fallback) can draw on.
/// Assembled from the same Riverpod providers the rest of the app already
/// uses — deliberately not a duplicate data layer, per docs/phase-2-plan.md.
class AssistantContext {
  const AssistantContext({
    required this.userName,
    required this.institution,
    required this.todaysClasses,
    required this.examCountdowns,
    required this.locations,
    required this.announcements,
    required this.academicMetric,
    required this.events,
    this.unavailable = const {},
  });

  final String userName;
  final InstitutionProfile institution;
  final List<TodayClass> todaysClasses;
  final List<ExamCountdown> examCountdowns;
  final List<CampusLocation> locations;
  final List<Announcement> announcements;
  final AcademicMetricResult academicMetric;
  final List<CampusEvent> events;

  /// Server-backed data that could not be loaded. The corresponding lists
  /// above are empty, which means "unknown", not "none".
  final Set<ContextSource> unavailable;

  List<InstitutionPortal> get portals => institution.portals;

  /// System-instruction text sent to Gemini, summarising the student's live data.
  String toSystemPrompt() {
    final scheduleSummary = todaysClasses.isEmpty
        ? 'No classes today.'
        : todaysClasses.map((c) => '${c.courseTitle} ${c.startTime}-${c.endTime} @ ${c.room ?? 'TBA'}').join('; ');
    final examSummary = examCountdowns.isEmpty
        ? 'No upcoming exams.'
        : examCountdowns
            .take(3)
            .map((e) => '${e.exam.courseCode} on ${e.formattedExamDate} (${e.formattedDaysRemaining})')
            .join('; ');
    final alertSummary = unavailable.contains(ContextSource.announcements)
        ? 'Unavailable.'
        : announcements.isEmpty
            ? 'None.'
            : announcements.take(3).map((a) => '[${a.category}] ${a.title}').join('; ');
    final eventSummary = unavailable.contains(ContextSource.events)
        ? 'Unavailable.'
        : events.isEmpty
            ? 'No upcoming events.'
            : events.take(3).map((e) => '${e.title} on ${e.eventDate.toLocal()}${e.location != null ? ' @ ${e.location}' : ''}').join('; ');
    final academicSummary = unavailable.contains(ContextSource.grades)
        ? '${academicMetric.metricLabel}: unavailable'
        : '${academicMetric.metricLabel}: ${academicMetric.formattedScore} '
            '(${academicMetric.classLabel.toLowerCase()}: ${academicMetric.honoursClass}'
            '${academicMetric.fgpa == null ? '; the official degree class can differ' : ''})';
    final unavailableNote = unavailable.isEmpty
        ? ''
        : '\nThe server could not be reached, so these are unavailable right now: '
            '${unavailable.map((s) => s.label).join(', ')}. Say you cannot see them rather than guessing.';

    return '''
You are Campus Companion AI, a helpful virtual assistant for $userName at ${institution.name}.
Current Context:
- $academicSummary
- Today's Classes: $scheduleSummary
- Upcoming Exams: $examSummary
- Active Alerts: $alertSummary
- Upcoming Events: $eventSummary$unavailableNote

Answer clearly, politely, with actionable times and venue names. If you don't know something, direct the student to the relevant tab (Timetable, Exams, Analytics, or Resources).''';
  }
}

/// Builds the context without letting one failed server call sink the rest.
/// Today's classes and exams are local, so they are always present; the four
/// server-backed pieces load in parallel and each falls back to "unavailable"
/// on its own. That keeps timetable, exam, portal and general questions
/// working offline or while a sleeping backend wakes up.
final assistantContextProvider = FutureProvider.autoDispose<AssistantContext>((ref) async {
  final user = ref.watch(sessionControllerProvider).valueOrNull;
  final institution = ref.watch(institutionControllerProvider);
  final todaysClasses = ref.watch(localTodaysClassesProvider);

  final exams = ref.watch(examsControllerProvider);
  final examCountdowns = ExamCountdownUtils.getSortedUpcomingExams(exams);

  final unavailable = <ContextSource>{};
  Future<T?> load<T>(ContextSource source, Future<T> future) async {
    try {
      return await future;
    } catch (_) {
      unavailable.add(source);
      return null;
    }
  }

  // Start all four before awaiting any, so they run concurrently.
  final locationsRequest = load(ContextSource.locations, ref.watch(allLocationsProvider.future));
  final announcementsRequest = load(ContextSource.announcements, ref.watch(announcementsProvider.future));
  final gradesRequest = load(ContextSource.grades, ref.watch(gradesProvider.future));
  final eventsRequest = load(ContextSource.events, ref.watch(eventsProvider.future));

  final locations = await locationsRequest;
  final announcements = await announcementsRequest;
  final grades = await gradesRequest;
  final events = await eventsRequest;

  return AssistantContext(
    userName: user?.fullName ?? 'Student',
    institution: institution,
    todaysClasses: todaysClasses,
    examCountdowns: examCountdowns,
    locations: locations ?? const [],
    announcements: announcements ?? const [],
    academicMetric: AcademicEngine.calculate(grades ?? const <CourseGrade>[], institution),
    events: events ?? const [],
    unavailable: unavailable,
  );
});
