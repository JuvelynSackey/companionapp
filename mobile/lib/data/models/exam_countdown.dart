import 'package:intl/intl.dart';
import 'exam.dart';

/// Ported from app/src/main/java/com/example/data/repository/ExamCountdownUtils.kt
class ExamCountdown {
  ExamCountdown({
    required this.exam,
    required this.daysRemaining,
    required this.isToday,
    required this.isTomorrow,
    required this.isPast,
    required this.formattedDaysRemaining,
    required this.formattedExamDate,
  });

  final Exam exam;
  final int daysRemaining;
  final bool isToday;
  final bool isTomorrow;
  final bool isPast;
  final String formattedDaysRemaining;
  final String formattedExamDate;
}

class ExamCountdownUtils {
  ExamCountdownUtils._();

  static final _isoDateFormat = DateFormat('yyyy-MM-dd');
  static final _displayDateFormat = DateFormat('EEE, MMM d, yyyy');

  static DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);

  static int calculateDaysRemaining(String examDateIso, {DateTime? now}) {
    try {
      final examDate = _midnight(_isoDateFormat.parseStrict(examDateIso.trim()));
      final today = _midnight(now ?? DateTime.now());
      return examDate.difference(today).inDays;
    } catch (_) {
      return 0;
    }
  }

  static String formatExamDateDisplay(String examDateIso) {
    try {
      final date = _isoDateFormat.parseStrict(examDateIso.trim());
      return _displayDateFormat.format(date);
    } catch (_) {
      return examDateIso;
    }
  }

  static ExamCountdown getCountdownInfo(Exam exam, {DateTime? now}) {
    final days = calculateDaysRemaining(exam.examDate, now: now);
    final isToday = days == 0;
    final isTomorrow = days == 1;
    final isPast = days < 0;

    final String formattedDaysRemaining;
    if (isToday) {
      formattedDaysRemaining = 'Today!';
    } else if (isTomorrow) {
      formattedDaysRemaining = 'Tomorrow (1 day)';
    } else if (isPast) {
      formattedDaysRemaining = '${-days}d ago';
    } else {
      formattedDaysRemaining = '$days days remaining';
    }

    return ExamCountdown(
      exam: exam,
      daysRemaining: days,
      isToday: isToday,
      isTomorrow: isTomorrow,
      isPast: isPast,
      formattedDaysRemaining: formattedDaysRemaining,
      formattedExamDate: formatExamDateDisplay(exam.examDate),
    );
  }

  static ExamCountdown? findNextUpcomingExam(List<Exam> exams, {DateTime? now}) {
    if (exams.isEmpty) return null;
    final sorted = getSortedUpcomingExams(exams, now: now);
    for (final e in sorted) {
      if (!e.isPast) return e;
    }
    return sorted.first;
  }

  static List<ExamCountdown> getSortedUpcomingExams(List<Exam> exams, {DateTime? now}) {
    final sorted = [...exams]..sort((a, b) {
        final dateCompare = a.examDate.compareTo(b.examDate);
        if (dateCompare != 0) return dateCompare;
        return a.startTime.compareTo(b.startTime);
      });
    return sorted.map((e) => getCountdownInfo(e, now: now)).toList();
  }
}
