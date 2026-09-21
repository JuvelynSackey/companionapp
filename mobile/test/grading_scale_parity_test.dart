import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/logic/academic_engine.dart';
import 'package:mobile/data/models/course_grade.dart';
import 'package:mobile/data/models/institution_profile.dart';

/// Checks the app's GPA engine against docs/grading-scale-ug.json, the same
/// file the backend smoke test checks the server against. If the two ever
/// disagree about a mark or a transcript, one of these two suites fails.
Map<String, dynamic> _loadFixture() {
  for (final path in ['../docs/grading-scale-ug.json', 'docs/grading-scale-ug.json']) {
    final file = File(path);
    if (file.existsSync()) return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }
  throw StateError('docs/grading-scale-ug.json not found (run flutter test from mobile/)');
}

CourseGrade _grade(double score, {int credits = 3, String code = 'DCIT 201'}) => CourseGrade(
      gradeId: 1,
      courseCode: code,
      courseTitle: 'Course',
      creditHours: credits,
      score: score,
      letterGrade: 'X',
      semester: 'Semester 1',
      passed: true,
    );

void main() {
  final fixture = _loadFixture();
  final scale = (fixture['scale'] as List).cast<Map<String, dynamic>>();
  final boundaryScores = (fixture['boundaryScores'] as List).map((s) => (s as num).toDouble()).toList();
  final transcripts = (fixture['transcripts'] as List).cast<Map<String, dynamic>>();

  Map<String, dynamic> bandFor(double score) => scale.firstWhere((band) => score >= (band['min'] as num));
  double pointsFor(double score) => (bandFor(score)['points'] as num).toDouble();
  String letterFor(double score) => bandFor(score)['letter'] as String;

  group('UG scale: grade points for a single mark', () {
    for (final score in boundaryScores) {
      test('$score -> ${letterFor(score)} (${pointsFor(score)} points)', () {
        final result = AcademicEngine.calculate([_grade(score)], InstitutionRegistry.ug);
        expect(result.scoreValue, pointsFor(score));
      });
    }

    test('the fixture is a complete scale: A down to a floor of 0, high to low', () {
      expect(scale.first['letter'], 'A');
      expect(scale.last['min'], 0);
      final mins = scale.map((b) => (b['min'] as num).toDouble()).toList();
      expect(mins, orderedEquals([...mins]..sort((a, b) => b.compareTo(a))));
    });
  });

  group('UG scale: cumulative GPA for a transcript', () {
    for (final transcript in transcripts) {
      test('${transcript['name']} -> ${transcript['expectedGpa']}', () {
        final grades = [
          for (final row in (transcript['rows'] as List).cast<Map<String, dynamic>>())
            _grade((row['score'] as num).toDouble(), credits: row['credits'] as int, code: row['course'] as String),
        ];

        final result = AcademicEngine.calculate(grades, InstitutionRegistry.ug);

        final expected = (transcript['expectedGpa'] as num).toStringAsFixed(2);
        expect(result.scoreValue.toStringAsFixed(2), expected);
        expect(result.formattedScore, '$expected / 4.00');
      });
    }
  });

  test('the engine does not depend on the order the grades arrive in', () {
    final rows = (transcripts.first['rows'] as List).cast<Map<String, dynamic>>();
    List<CourseGrade> build(Iterable<Map<String, dynamic>> r) => [
          for (final row in r) _grade((row['score'] as num).toDouble(), credits: row['credits'] as int),
        ];

    final forward = AcademicEngine.calculate(build(rows), InstitutionRegistry.ug).scoreValue;
    final backward = AcademicEngine.calculate(build(rows.reversed), InstitutionRegistry.ug).scoreValue;

    expect(forward, closeTo(backward, 1e-9));
  });
}
