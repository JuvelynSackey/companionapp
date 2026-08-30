import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/exam.dart';
import 'package:mobile/data/models/exam_countdown.dart';

Exam _exam(String date) => Exam(
      id: 'x',
      courseCode: 'DCIT 201',
      courseTitle: 'Mathematics',
      examDate: date,
      startTime: '09:00',
      endTime: '12:00',
      venue: 'Room 204',
    );

void main() {
  final now = DateTime(2026, 8, 30);

  test('today exam formats as "Today!"', () {
    final info = ExamCountdownUtils.getCountdownInfo(_exam('2026-08-30'), now: now);
    expect(info.daysRemaining, 0);
    expect(info.isToday, isTrue);
    expect(info.formattedDaysRemaining, 'Today!');
  });

  test('tomorrow exam formats as "Tomorrow (1 day)"', () {
    final info = ExamCountdownUtils.getCountdownInfo(_exam('2026-08-31'), now: now);
    expect(info.isTomorrow, isTrue);
    expect(info.formattedDaysRemaining, 'Tomorrow (1 day)');
  });

  test('future exam counts days remaining', () {
    final info = ExamCountdownUtils.getCountdownInfo(_exam('2026-09-09'), now: now);
    expect(info.daysRemaining, 10);
    expect(info.formattedDaysRemaining, '10 days remaining');
  });

  test('past exam counts days ago and is marked past', () {
    final info = ExamCountdownUtils.getCountdownInfo(_exam('2026-08-20'), now: now);
    expect(info.isPast, isTrue);
    expect(info.formattedDaysRemaining, '10d ago');
  });

  test('findNextUpcomingExam skips past exams and picks the earliest future one', () {
    final exams = [_exam('2026-08-20'), _exam('2026-09-09'), _exam('2026-09-01')];
    final next = ExamCountdownUtils.findNextUpcomingExam(exams, now: now);
    expect(next!.exam.examDate, '2026-09-01');
  });

  test('findNextUpcomingExam falls back to the chronologically earliest exam when all are past', () {
    final exams = [_exam('2026-08-20'), _exam('2026-08-01')];
    final next = ExamCountdownUtils.findNextUpcomingExam(exams, now: now);
    expect(next!.exam.examDate, '2026-08-01');
  });

  test('getSortedUpcomingExams orders chronologically', () {
    final exams = [_exam('2026-09-09'), _exam('2026-08-30'), _exam('2026-09-01')];
    final sorted = ExamCountdownUtils.getSortedUpcomingExams(exams, now: now);
    expect(sorted.map((e) => e.exam.examDate).toList(), ['2026-08-30', '2026-09-01', '2026-09-09']);
  });
}
