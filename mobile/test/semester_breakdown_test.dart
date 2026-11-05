import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/logic/academic_engine.dart';
import 'package:mobile/data/models/course_grade.dart';
import 'package:mobile/data/models/institution_profile.dart';

// Marks chosen inside each UG band: A 85, B+ 77, B 72, C+ 67, C 62, D+ 57, E 47.
var _id = 0;
CourseGrade _g(String code, double score, String semester, {int credits = 3}) => CourseGrade(
      gradeId: _id++, courseCode: code, courseTitle: code, creditHours: credits, score: score,
      letterGrade: '', semester: semester, passed: score >= 45,
    );

void main() {
  const s1 = 'Semester 1 - 2022/2023';
  const s2 = 'Semester 2 - 2022/2023';
  const s3 = 'Semester 1 - 2023/2024';

  // The author's first two semesters, as on the UG transcript (CGPA 2.08, then 2.23).
  final grades = [
    _g('DCIT 201', 57, s3), // listed out of order on purpose
    _g('DCIT 101', 62, s1), _g('DCIT 103', 67, s1), _g('DCIT 105', 67, s1),
    _g('ECON 101', 47, s1), _g('STAT 111', 62, s1), _g('UGRC 150', 72, s1),
    _g('DCIT 102', 67, s2), _g('DCIT 104', 67, s2), _g('ECON 102', 47, s2), _g('MATH 122', 57, s2),
    _g('STAT 112', 77, s2), _g('UGBS 104', 67, s2), _g('UGRC 110', 77, s2),
  ];

  test('semesters come out in academic order, each with its GPA and the running CGPA', () {
    final semesters = AcademicEngine.semesterBreakdown(grades, InstitutionRegistry.ug);

    expect(semesters.map((s) => s.semester), [s1, s2, s3]);
    expect(semesters[0].credits, 18);
    expect(semesters[0].gpa.toStringAsFixed(2), '2.08');
    expect(semesters[0].cgpa.toStringAsFixed(2), '2.08', reason: 'matches the transcript');
    expect(semesters[1].gpa.toStringAsFixed(2), '2.36');
    expect(semesters[1].cumulativeCredits, 39);
    expect(semesters[1].cgpa.toStringAsFixed(2), '2.23', reason: 'matches the transcript');
    expect(semesters[2].courses.single.courseCode, 'DCIT 201');
  });

  test('courses within a semester are sorted by code, and unknown semester names go last', () {
    final semesters = AcademicEngine.semesterBreakdown(
      [_g('DCIT 205', 85, 'Summer school'), _g('DCIT 203', 85, s1), _g('DCIT 201', 85, s1)],
      InstitutionRegistry.ug,
    );
    expect(semesters.map((s) => s.semester), [s1, 'Summer school']);
    expect(semesters.first.courses.map((c) => c.courseCode), ['DCIT 201', 'DCIT 203']);
  });
}
