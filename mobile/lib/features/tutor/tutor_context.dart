import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../data/models/course.dart';
import '../../data/models/course_grade.dart';
import '../../data/models/exam_countdown.dart';
import '../analytics/analytics_providers.dart';
import '../exams/exams_providers.dart';

/// Everything the AI Tutor can draw on for one course — mirrors
/// AssistantContext's shape/toSystemPrompt() template in
/// context_aggregator.dart, but scoped to a single Course instead of the
/// whole campus. Assembled from the same providers the rest of the app
/// already uses, not a duplicate data layer.
class TutorContext {
  const TutorContext({
    required this.course,
    required this.grade,
    required this.examCountdown,
  });

  final Course course;
  final CourseGrade? grade;
  final ExamCountdown? examCountdown;

  /// [slidesName] is set when the student attached lecture slides.
  String toSystemPrompt({String? slidesName}) {
    final gradeSummary =
        grade == null ? 'No recorded grade yet.' : '${grade!.score.toStringAsFixed(1)}% (${grade!.letterGrade})';
    final examSummary = examCountdown == null
        ? 'No upcoming exam scheduled.'
        : '${examCountdown!.formattedExamDate} (${examCountdown!.formattedDaysRemaining})';

    return '''
You are Campus Companion AI Tutor, helping a student with ${course.courseCode} - ${course.courseTitle} (taught by ${course.lecturer}, ${course.creditHours} credit hours).
Current Context:
- Current grade in this course: $gradeSummary
- Next exam for this course: $examSummary

Write maths in plain text (for example 1 × 8 + 0 × 4 = 8), never in LaTeX. Act as a patient, encouraging tutor for this specific course only. Explain concepts clearly with examples when asked, and when asked for practice questions, generate 3-5 questions relevant to a course at this level with brief answers at the end. If asked about something outside this course, gently redirect the student to the general AI Assistant instead.${slidesName == null ? '' : '''

The student has attached lecture slides for this course ("$slidesName"). Base your answers on these slides, mention the slide or page a point comes from where you can, and say so if the slides do not cover the question.'''}''';
  }
}

final tutorContextProvider = FutureProvider.autoDispose.family<TutorContext, int>((ref, courseId) async {
  final courses = await ref.watch(coursesProvider.future);
  final course = courses.firstWhere((c) => c.courseId == courseId);

  final grades = await ref.watch(gradesProvider.future);
  final matchingGrades = grades.where((g) => g.courseCode == course.courseCode);
  final grade = matchingGrades.isEmpty ? null : matchingGrades.first;

  final exams = ref.watch(examsControllerProvider);
  final matchingExams = ExamCountdownUtils.getSortedUpcomingExams(exams)
      .where((e) => e.exam.courseCode == course.courseCode && !e.isPast);
  final examCountdown = matchingExams.isEmpty ? null : matchingExams.first;

  return TutorContext(course: course, grade: grade, examCountdown: examCountdown);
});
