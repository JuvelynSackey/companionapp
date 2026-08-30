import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/logic/academic_engine.dart';
import 'package:mobile/data/models/campus_location.dart';
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
  );
}

void main() {
  group('LocalAssistantEngine', () {
    test('library keyword returns seat availability from fixture data', () {
      final response = LocalAssistantEngine.respond('any seats in the library?', _buildContext());
      expect(response, contains('Libraries'));
      expect(response, contains('Main Library'));
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
    });
  });
}
