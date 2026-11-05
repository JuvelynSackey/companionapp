import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/course.dart';
import 'package:mobile/features/tutor/tutor_context.dart';

void main() {
  final course = Course(courseId: 1, courseCode: 'DCIT 305', courseTitle: 'Database Fundamentals', lecturer: 'Dept. of Computer Science', creditHours: 3);
  final context = TutorContext(course: course, grade: null, examCountdown: null);

  test('with slides attached, the tutor is told to answer from them and cite pages', () {
    final prompt = context.toSystemPrompt(slidesName: 'week3.pdf');
    expect(prompt, contains('"week3.pdf"'));
    expect(prompt, contains('Base your answers on these slides'));
  });

  test('without slides, the prompt does not mention any', () {
    expect(context.toSystemPrompt(), isNot(contains('slides')));
  });
}
