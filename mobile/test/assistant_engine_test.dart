import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/logic/academic_engine.dart';
import 'package:mobile/data/models/campus_location.dart';
import 'package:mobile/data/models/campus_event.dart';
import 'package:mobile/data/models/course_grade.dart';
import 'package:mobile/data/models/dashboard_data.dart';
import 'package:mobile/data/models/exam.dart';
import 'package:mobile/data/models/exam_countdown.dart';
import 'package:mobile/data/models/institution_profile.dart';
import 'package:mobile/features/assistant/context_aggregator.dart';
import 'package:mobile/features/assistant/local_assistant_engine.dart';

AssistantContext _buildContext({
  List<TodayClass> classes = const [],
  List<ExamCountdown> exams = const [],
  List<CampusLocation> locations = const [],
  List<CourseGrade> grades = const [],
  List<CampusEvent> events = const [],
  InstitutionProfile institution = InstitutionRegistry.ug,
}) {
  return AssistantContext(
    userName: 'Ekow',
    institution: institution,
    todaysClasses: classes,
    examCountdowns: exams,
    locations: locations,
    announcements: const [],
    academicMetric: AcademicEngine.calculate(grades, institution),
    events: events,
  );
}

void main() {
  group('LocalAssistantEngine', () {
    test('library keyword lists the real library locations, with no invented seat counts', () {
      final locations = [
        CampusLocation(locationId: 1, name: 'Balme Library', category: 'library', description: 'Main library.', latitude: 5.65, longitude: -0.18),
        CampusLocation(locationId: 2, name: 'Great Hall', category: 'other', description: '', latitude: 5.65, longitude: -0.18),
      ];
      final response = LocalAssistantEngine.respond('any seats in the library?', _buildContext(locations: locations));
      expect(response, contains('Campus Libraries'));
      expect(response, contains('Balme Library'));
      expect(response, isNot(contains('Great Hall')), reason: 'only libraries');
      expect(response, isNot(contains('seats free')));
      expect(response, isNot(contains('vacant')));
    });

    test('library keyword with no libraries on the map says so', () {
      expect(LocalAssistantEngine.respond('where is the library?', _buildContext()), contains('No libraries are listed'));
    });

    test('exam keyword returns the next non-past exam, skipping past ones', () {
      final past = ExamCountdownUtils.getCountdownInfo(
        Exam(id: '1', courseCode: 'OLD 101', courseTitle: 'Old', examDate: '2020-01-01', startTime: '09:00', endTime: '12:00', venue: 'A'),
        now: DateTime(2026, 1, 1),
      );
      final future = ExamCountdownUtils.getCountdownInfo(
        Exam(id: '2', courseCode: 'DCIT 201', courseTitle: 'Mathematics', examDate: '2026-09-09', startTime: '09:00', endTime: '12:00', venue: 'Room 204'),
        now: DateTime(2026, 1, 1),
      );
      final response = LocalAssistantEngine.respond('when is my next exam', _buildContext(exams: [past, future]));
      expect(response, contains('DCIT 201'));
      expect(response, isNot(contains('OLD 101')));
    });

    test('exam keyword with no upcoming exams gives a helpful message, not a crash', () {
      final response = LocalAssistantEngine.respond('when should I leave for my exam', _buildContext());
      expect(response, contains("don't have any upcoming exams"));
    });

    test('class keyword lists today\'s classes', () {
      final classes = [
        TodayClass(scheduleId: 1, courseTitle: 'Physics', lecturer: 'Prof. K', room: 'Lab 3', startTime: '09:00', endTime: '10:30', inProgress: false),
      ];
      final response = LocalAssistantEngine.respond('what classes do I have today', _buildContext(classes: classes));
      expect(response, contains('Physics'));
      expect(response, contains('Lab 3'));
    });

    test('a location name mentioned in the query returns its details', () {
      final locations = [
        CampusLocation(locationId: 1, name: 'Balme Library', category: 'library', description: 'Main library.', latitude: 5.65, longitude: -0.18),
      ];
      final response = LocalAssistantEngine.respond('how do I get to balme', _buildContext(locations: locations));
      expect(response, contains('Balme Library'));
      expect(response, contains('Main library.'));
    });

    test('gpa keyword reports the institution-aware metric and honours gap', () {
      final grades = [
        CourseGrade(gradeId: 1, courseCode: 'DCIT 201', courseTitle: 'Mathematics', creditHours: 3, score: 70, letterGrade: 'B', semester: 'S1', passed: true),
      ];
      final response = LocalAssistantEngine.respond('calculate my gpa', _buildContext(grades: grades));
      expect(response, contains('Cumulative GPA'));
      expect(response, contains('Second Class'));
    });

    test('portal keyword lists the institution\'s real portals', () {
      final response = LocalAssistantEngine.respond('how do I register on my portal', _buildContext());
      expect(response, contains('MIS Web Portal'));
      expect(response, contains('Sakai LMS'));
    });

    test('event keyword lists upcoming events', () {
      final events = [
        CampusEvent(
          eventId: 1,
          title: 'Freshers Night',
          description: 'Welcome party',
          eventDate: DateTime(2026, 9, 20, 18, 0),
          location: 'Great Hall',
          clubName: 'SRC',
          attendeeCount: 120,
          isRegistered: false,
        ),
      ];
      final response = LocalAssistantEngine.respond('any events happening this week?', _buildContext(events: events));
      expect(response, contains('Freshers Night'));
      expect(response, contains('Great Hall'));
    });

    test('event keyword with no upcoming events gives a helpful message, not a crash', () {
      final response = LocalAssistantEngine.respond('what events are on campus', _buildContext());
      expect(response, contains('No upcoming events'));
    });

    test('unmatched query falls back to the general help menu, addressed by name', () {
      final response = LocalAssistantEngine.respond('asdkjfhaskdjfh', _buildContext());
      expect(response, contains('Akwaaba, Ekow'));
    });
  });

  group('AssistantContext.toSystemPrompt', () {
    test('includes the user, institution, and academic metric', () {
      final grades = [
        CourseGrade(gradeId: 1, courseCode: 'DCIT 201', courseTitle: 'Mathematics', creditHours: 3, score: 85, letterGrade: 'A', semester: 'S1', passed: true),
      ];
      final prompt = _buildContext(grades: grades).toSystemPrompt();
      expect(prompt, contains('Ekow'));
      expect(prompt, contains('University of Ghana'));
      expect(prompt, contains('Cumulative GPA'));
    });

    test('reports "no classes"/"no exams" when there is nothing scheduled', () {
      final prompt = _buildContext().toSystemPrompt();
      expect(prompt, contains('No classes today.'));
      expect(prompt, contains('No upcoming exams.'));
      expect(prompt, contains('No upcoming events.'));
    });

    test('includes upcoming events when present', () {
      final events = [
        CampusEvent(
          eventId: 1,
          title: 'Tech Fair',
          description: 'Annual expo',
          eventDate: DateTime(2026, 10, 1, 10, 0),
          location: 'JQB Auditorium',
          clubName: null,
          attendeeCount: 40,
          isRegistered: false,
        ),
      ];
      final prompt = _buildContext(events: events).toSystemPrompt();
      expect(prompt, contains('Tech Fair'));
    });
  });
}
