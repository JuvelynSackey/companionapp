import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/logic/academic_engine.dart';
import 'package:mobile/data/models/course_grade.dart';
import 'package:mobile/data/models/institution_profile.dart';

CourseGrade _grade(double score, {int credits = 3}) => CourseGrade(
      gradeId: 1,
      courseCode: 'DCIT 201',
      courseTitle: 'Mathematics',
      creditHours: credits,
      score: score,
      letterGrade: 'A',
      semester: 'Semester 1',
      passed: score >= 50,
    );

void main() {
  test('UG (gpa4_0): a straight A average scores 4.00 and First Class', () {
    final result = AcademicEngine.calculate([_grade(85), _grade(90)], InstitutionRegistry.ug);
    expect(result.scoreValue, 4.0);
    expect(result.formattedScore, '4.00 / 4.00');
    expect(result.honoursClass, 'First Class Honours');
    expect(result.isPercentage, isFalse);
  });

  test('the class is labelled an estimate from the CGPA (or CWA), not the official degree class', () {
    // UG classifies on the FGPA, which weights Levels 100-400 as 1:1:2:2
    // (Regulations for Junior Members, 2017, 9.31); this engine does not.
    expect(AcademicEngine.calculate([_grade(85)], InstitutionRegistry.ug).classLabel, 'Estimated class (from CGPA)');
    expect(AcademicEngine.calculate([_grade(85)], InstitutionRegistry.knust).classLabel, 'Estimated class (from CWA)');
  });

  test('UG (gpa4_0): credit-weighted average across mixed grades', () {
    // 3 credits @ 80 (4.0) + 2 credits @ 60 (2.0) = (12 + 4) / 5 = 3.2
    final result = AcademicEngine.calculate(
      [_grade(80, credits: 3), _grade(60, credits: 2)],
      InstitutionRegistry.ug,
    );
    expect(result.scoreValue, closeTo(3.2, 0.001));
    expect(result.honoursClass, 'Second Class (Upper)');
  });

  test('KNUST (CWA): score passes through as a percentage, not a GPA point', () {
    final result = AcademicEngine.calculate([_grade(72)], InstitutionRegistry.knust);
    expect(result.scoreValue, 72.0);
    expect(result.formattedScore, '72.00% CWA');
    expect(result.isPercentage, isTrue);
    expect(result.honoursClass, 'First Class Honours'); // KNUST cutoff is 70+
  });

  test('ATU (scale5_0): uses the 5.0-scale breakpoints, not the 4.0 ones', () {
    final result = AcademicEngine.calculate([_grade(85)], InstitutionRegistry.atu);
    expect(result.scoreValue, 5.0);
    expect(result.formattedScore, '5.00 / 5.00');
  });

  test('Ashesi: distinct honours labels (Summa/Magna/Cum Laude) apply', () {
    final result = AcademicEngine.calculate([_grade(96)], InstitutionRegistry.ashesi); // 96 -> 4.0 -> Summa
    expect(result.honoursClass, 'Summa Cum Laude');
  });

  test('empty grade list returns a "No Data" placeholder, not a crash', () {
    final result = AcademicEngine.calculate([], InstitutionRegistry.ug);
    expect(result.honoursClass, 'No Data');
    expect(result.scoreValue, 0);
    expect(result.totalCredits, 0);
  });

  test('a below-45 score floors to 0.0 grade points on the gpa4_0 scale', () {
    final result = AcademicEngine.calculate([_grade(20)], InstitutionRegistry.ug);
    expect(result.scoreValue, 0.0);
    expect(result.honoursClass, 'Fail');
  });

  test('classify() returns the lowest threshold as a safety fallback for an out-of-range score', () {
    final threshold = AcademicEngine.classify(-5, InstitutionRegistry.ug);
    expect(threshold.title, 'Fail');
  });
}
