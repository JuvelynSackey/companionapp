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

  group('FGPA (UG, Regulations for Junior Members 2017, 9.31: Levels 100-400 weighted 1:1:2:2)', () {
    CourseGrade at(String code, double score, {int credits = 3}) => CourseGrade(
          gradeId: 1,
          courseCode: code,
          courseTitle: 'Course',
          creditHours: credits,
          score: score,
          letterGrade: 'A',
          semester: 'Semester 1',
          passed: score >= 50,
        );

    test("a course's level is the first digit of its three-digit number (9.13)", () {
      expect(AcademicEngine.levelOf('DCIT 201'), 200);
      expect(AcademicEngine.levelOf('UGRC 110'), 100);
      expect(AcademicEngine.levelOf('CSCD415'), 400);
      expect(AcademicEngine.levelOf('PROJECT'), isNull);
      expect(AcademicEngine.levelOf('DCIT 2010'), isNull, reason: 'four digits is not a course number');
    });

    test('weak early levels count half as much: the FGPA gives a higher class than the CGPA', () {
      // Levels 100 and 200 at D (1.0), Levels 300 and 400 at A (4.0), equal credits.
      // CGPA = 2.50 (Second Lower). FGPA = (1 + 1 + 2*4 + 2*4) / 6 = 3.00 (Second Upper).
      final result = AcademicEngine.calculate(
        [at('DCIT 101', 50), at('DCIT 201', 50), at('DCIT 301', 85), at('DCIT 401', 85)],
        InstitutionRegistry.ug,
      );
      expect(result.scoreValue, closeTo(2.50, 1e-9), reason: 'the headline figure stays the CGPA');
      expect(result.fgpa, closeTo(3.00, 1e-9));
      expect(result.honoursClass, 'Second Class (Upper)');
      expect(result.classLabel, 'Class (from FGPA 3.00)');
    });

    test('strong early levels count half as much: the FGPA gives a lower class than the CGPA', () {
      // Levels 100 and 200 at A (4.0), Levels 300 and 400 at C (2.0).
      // CGPA = 3.00 (Second Upper). FGPA = (4 + 4 + 2*2 + 2*2) / 6 = 2.67 (Second Lower).
      final result = AcademicEngine.calculate(
        [at('DCIT 101', 85), at('DCIT 201', 85), at('DCIT 301', 60), at('DCIT 401', 60)],
        InstitutionRegistry.ug,
      );
      expect(result.scoreValue, closeTo(3.00, 1e-9));
      expect(result.fgpa, closeTo(8 / 3, 1e-9));
      expect(result.honoursClass, 'Second Class (Lower)');
    });

    test("each level's GPA is credit-weighted first, then the levels are combined", () {
      // Level 100: one 3-credit A (GPA 4.0). Level 200: two 3-credit C (GPA 2.0).
      // CGPA = (12 + 12) / 9 = 2.67, but FGPA = (4.0 + 2.0) / 2 = 3.00: the levels
      // count equally whatever their credits.
      final result = AcademicEngine.calculate(
        [at('DCIT 101', 85), at('DCIT 201', 60), at('DCIT 203', 60)],
        InstitutionRegistry.ug,
      );
      expect(result.scoreValue, closeTo(24 / 9, 1e-9));
      expect(result.fgpa, closeTo(3.00, 1e-9));
      expect(result.honoursClass, 'Second Class (Upper)');
    });

    test('a course with no readable level falls back to the CGPA, labelled an estimate', () {
      final result = AcademicEngine.calculate([at('DCIT 201', 85), at('PROJECT', 60)], InstitutionRegistry.ug);
      expect(result.fgpa, isNull);
      expect(result.classLabel, 'Estimated class (from CGPA)');
    });

    test('an institution without level weighting keeps the cumulative estimate', () {
      final result = AcademicEngine.calculate([at('DCIT 201', 85)], InstitutionRegistry.knust);
      expect(result.fgpa, isNull);
      expect(result.classLabel, 'Estimated class (from CWA)');
    });
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
