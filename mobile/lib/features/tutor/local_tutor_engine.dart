import 'tutor_context.dart';

/// Offline fallback for the AI Tutor when Gemini is unavailable — kept
/// deliberately simple (a single static message) rather than a full
/// keyword-branch engine like LocalAssistantEngine's, since there's no rich
/// local knowledge base for arbitrary course content to draw on.
class LocalTutorEngine {
  LocalTutorEngine._();

  static String respond(String query, TutorContext context) {
    final course = context.course;
    return "I can't reach the AI Tutor right now, so I can only share what I already know about "
        "${course.courseCode} - ${course.courseTitle}. "
        "${context.grade != null ? 'Your current grade: ${context.grade!.score.toStringAsFixed(1)}% (${context.grade!.letterGrade}). ' : ''}"
        "${context.examCountdown != null ? 'Next exam: ${context.examCountdown!.formattedExamDate} (${context.examCountdown!.formattedDaysRemaining}). ' : ''}"
        "Please check your connection and try again for a real explanation or practice questions.";
  }
}
