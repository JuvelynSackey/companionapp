import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/logic/academic_engine.dart';
import '../../data/models/announcement.dart';
import '../../data/models/campus_event.dart';
import '../../data/models/campus_location.dart';
import '../../data/models/dashboard_data.dart';
import '../../data/models/exam_countdown.dart';
import '../../data/models/institution_profile.dart';
import '../../data/models/resource_models.dart';
import '../alerts/alerts_providers.dart';
import '../analytics/analytics_providers.dart';
import '../auth/session_controller.dart';
import '../dashboard/dashboard_providers.dart';
import '../events/events_providers.dart';
import '../exams/exams_providers.dart';
import '../locations/locations_providers.dart';
import '../onboarding/institution_controller.dart';

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
  });

  final String userName;
  final InstitutionProfile institution;
  final List<TodayClass> todaysClasses;
  final List<ExamCountdown> examCountdowns;
  final List<CampusLocation> locations;
  final List<Announcement> announcements;
  final AcademicMetricResult academicMetric;
  final List<CampusEvent> events;

  List<LibraryInfo> get libraries => ResourceFixtures.libraries;
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
    final alertSummary = announcements.isEmpty
        ? 'None.'
        : announcements.take(3).map((a) => '[${a.category}] ${a.title}').join('; ');
    final eventSummary = events.isEmpty
        ? 'No upcoming events.'
        : events.take(3).map((e) => '${e.title} on ${e.eventDate.toLocal()}${e.location != null ? ' @ ${e.location}' : ''}').join('; ');

    return '''
You are Campus Companion AI, a helpful virtual assistant for $userName at ${institution.name}.
Current Context:
- ${academicMetric.metricLabel}: ${academicMetric.formattedScore} (${academicMetric.honoursClass})
- Today's Classes: $scheduleSummary
- Upcoming Exams: $examSummary
- Active Alerts: $alertSummary
- Upcoming Events: $eventSummary

Answer clearly, politely, with actionable times and venue names. If you don't know something, direct the student to the relevant tab (Timetable, Exams, Analytics, or Resources).''';
  }
}

final assistantContextProvider = FutureProvider.autoDispose<AssistantContext>((ref) async {
  final user = ref.watch(sessionControllerProvider).valueOrNull;
  final institution = ref.watch(institutionControllerProvider);

  final dashboard = await ref.watch(dashboardViewProvider.future);
  final locations = await ref.watch(allLocationsProvider.future);
  final announcements = await ref.watch(announcementsProvider.future);
  final grades = await ref.watch(gradesProvider.future);
  final events = await ref.watch(eventsProvider.future);

  final exams = ref.watch(examsControllerProvider);
  final examCountdowns = ExamCountdownUtils.getSortedUpcomingExams(exams);

  return AssistantContext(
    userName: user?.fullName ?? 'Student',
    institution: institution,
    todaysClasses: dashboard.todaysClasses,
    examCountdowns: examCountdowns,
    locations: locations,
    announcements: announcements,
    academicMetric: AcademicEngine.calculate(grades, institution),
    events: events,
  );
});
