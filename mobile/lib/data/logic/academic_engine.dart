import 'package:flutter/material.dart';
import '../models/course_grade.dart';
import '../models/institution_profile.dart';

/// Institution-aware GPA/CWA + honours classification, computed client-side
/// from the backend's raw per-course `score` (0-100).
///
/// The backend is single-tenant and grades on the University of Ghana scale;
/// the 4.0 breakpoints below are that same scale (checked against
/// docs/grading-scale-ug.json by grading_scale_parity_test.dart, which the
/// server is also checked against). This engine re-derives points from the raw
/// score using each institution's own breakpoints, so the other institutions'
/// scales (5.0, 4.3, CWA) work without backend changes. For those, the
/// backend's `letterGrade` label is still the UG one.
///
/// The headline figure is the plain credit-weighted average (the CGPA, or
/// CWA). Where the institution classifies on a level-weighted average (the
/// University of Ghana's FGPA weights Levels 100-400 as 1:1:2:2; Regulations
/// for Junior Members, September 2017, 9.31) and every course's level can be
/// read from its code, the class comes from that FGPA; otherwise it is an
/// estimate from the CGPA. [classLabel] says which.
class AcademicMetricResult {
  const AcademicMetricResult({
    required this.scoreValue,
    required this.formattedScore,
    required this.honoursClass,
    required this.honoursColor,
    required this.totalCredits,
    required this.isPercentage,
    required this.metricLabel,
    required this.statusSummary,
    this.fgpa,
  });

  final double scoreValue;
  final String formattedScore;
  final String honoursClass;
  final Color honoursColor;
  final int totalCredits;
  final bool isPercentage;
  final String metricLabel;
  final String statusSummary;

  /// The level-weighted average the class was taken from, or null when the
  /// class is estimated from the cumulative average.
  final double? fgpa;

  /// Shown wherever [honoursClass] is, so the reader knows what it rests on.
  String get classLabel => fgpa != null
      ? 'Class (from FGPA ${fgpa!.toStringAsFixed(2)})'
      : 'Estimated class (from ${isPercentage ? 'CWA' : 'CGPA'})';
}

/// One semester of the transcript view (see AcademicEngine.semesterBreakdown).
class SemesterSummary {
  const SemesterSummary({
    required this.semester,
    required this.courses,
    required this.credits,
    required this.gpa,
    required this.cumulativeCredits,
    required this.cgpa,
  });

  final String semester;
  final List<CourseGrade> courses;
  final int credits;
  final double gpa;
  final int cumulativeCredits;
  final double cgpa;
}

class AcademicEngine {
  AcademicEngine._();

  static const _noDataColor = Color(0xFF6B7280);

  /// Score -> point breakpoints per grading system. KNUST's CWA is already
  /// a percentage average, so it has no conversion table (see _pointForScore).
  static const _gpa4_0Breakpoints = [
    (80.0, 4.0), (75.0, 3.5), (70.0, 3.0), (65.0, 2.5),
    (60.0, 2.0), (55.0, 1.5), (50.0, 1.0), (45.0, 0.5),
  ];

  static const _scale5_0Breakpoints = [
    (80.0, 5.0), (70.0, 4.0), (60.0, 3.0), (50.0, 2.0), (45.0, 1.0),
  ];

  static const _scale4_3Breakpoints = [
    (80.0, 4.3), (75.0, 3.7), (70.0, 3.3), (65.0, 2.7),
    (60.0, 2.3), (55.0, 1.7), (50.0, 1.3), (45.0, 0.7),
  ];

  static double _pointForScore(double score, GradingSystemType system) {
    if (system == GradingSystemType.knustCwa) return score;

    final breakpoints = switch (system) {
      GradingSystemType.gpa4_0 => _gpa4_0Breakpoints,
      GradingSystemType.scale5_0 => _scale5_0Breakpoints,
      GradingSystemType.scale4_3 => _scale4_3Breakpoints,
      GradingSystemType.knustCwa => throw StateError('handled above'),
    };
    for (final (minScore, point) in breakpoints) {
      if (score >= minScore) return point;
    }
    return 0.0;
  }

  /// Orders semester names like "Semester 2 - 2023/2024" by academic year,
  /// then semester; names in any other form come last, alphabetically.
  static int _semesterOrder(String semester) {
    final match = RegExp(r'Semester\s*(\d)\D+(\d{4})').firstMatch(semester);
    return match == null ? 1 << 30 : int.parse(match.group(2)!) * 10 + int.parse(match.group(1)!);
  }

  /// The transcript view: each semester in order with its own GPA (credit-
  /// weighted average of that semester's courses) and the running CGPA up to
  /// and including it, as on a UG transcript (CCT / CGPA per semester).
  static List<SemesterSummary> semesterBreakdown(List<CourseGrade> grades, InstitutionProfile institution) {
    final bySemester = <String, List<CourseGrade>>{};
    for (final grade in grades) {
      bySemester.putIfAbsent(grade.semester, () => []).add(grade);
    }
    final names = bySemester.keys.toList()
      ..sort((a, b) {
        final byOrder = _semesterOrder(a).compareTo(_semesterOrder(b));
        return byOrder != 0 ? byOrder : a.compareTo(b);
      });

    var runningCredits = 0;
    var runningPoints = 0.0;
    return [
      for (final name in names)
        () {
          final courses = bySemester[name]!..sort((a, b) => a.courseCode.compareTo(b.courseCode));
          var credits = 0;
          var points = 0.0;
          for (final grade in courses) {
            credits += _credits(grade);
            points += _credits(grade) * _pointForScore(grade.score, institution.gradingSystem);
          }
          runningCredits += credits;
          runningPoints += points;
          return SemesterSummary(
            semester: name,
            courses: courses,
            credits: credits,
            gpa: credits == 0 ? 0 : points / credits,
            cumulativeCredits: runningCredits,
            cgpa: runningCredits == 0 ? 0 : runningPoints / runningCredits,
          );
        }(),
    ];
  }

  /// The level of a course from its code: the first digit of its three-digit
  /// number (DCIT 201 is Level 200, UGRC 110 Level 100; Regulations for
  /// Junior Members, 9.13). Null when the code has no such number.
  static int? levelOf(String courseCode) {
    final match = RegExp(r'(?<!\d)(\d)\d{2}(?!\d)').firstMatch(courseCode);
    return match == null ? null : int.parse(match.group(1)!) * 100;
  }

  static int _credits(CourseGrade grade) => grade.creditHours < 1 ? 1 : grade.creditHours;

  /// Credits and grade points earned at each level, or null when the
  /// institution has no level weighting or any course's level is unknown or
  /// unweighted (then no level-weighted average can be formed honestly).
  static Map<int, ({int credits, double points})>? levelTotals(List<CourseGrade> grades, InstitutionProfile institution) {
    if (institution.levelWeights.isEmpty || grades.isEmpty) return null;
    final totals = <int, ({int credits, double points})>{};
    for (final grade in grades) {
      final level = levelOf(grade.courseCode);
      if (level == null || !institution.levelWeights.containsKey(level)) return null;
      final credits = _credits(grade);
      final previous = totals[level] ?? (credits: 0, points: 0.0);
      totals[level] = (
        credits: previous.credits + credits,
        points: previous.points + credits * _pointForScore(grade.score, institution.gradingSystem),
      );
    }
    return totals;
  }

  /// The weighted mean of each level's GPA, over the levels taken so far
  /// (1:1:2:2 at UG). With every level complete this is the FGPA; earlier in
  /// the programme it is the same formula over the levels done.
  static double weightedLevelAverage(Map<int, ({int credits, double points})> totals, Map<int, int> weights) {
    var weighted = 0.0;
    var weightSum = 0;
    totals.forEach((level, t) {
      if (t.credits == 0) return;
      weighted += weights[level]! * (t.points / t.credits);
      weightSum += weights[level]!;
    });
    return weightSum == 0 ? 0 : weighted / weightSum;
  }

  static HonoursThreshold classify(double score, InstitutionProfile institution) {
    for (final threshold in institution.honoursThresholds) {
      if (score >= threshold.minScore) return threshold;
    }
    if (institution.honoursThresholds.isNotEmpty) return institution.honoursThresholds.last;
    return const HonoursThreshold(title: 'Pass', minScore: 0, maxScore: 100, color: _noDataColor);
  }

  static double maxScaleFor(GradingSystemType system) => switch (system) {
        GradingSystemType.gpa4_0 => 4.0,
        GradingSystemType.scale5_0 => 5.0,
        GradingSystemType.scale4_3 => 4.3,
        GradingSystemType.knustCwa => 100.0,
      };

  static AcademicMetricResult calculate(List<CourseGrade> grades, InstitutionProfile institution) {
    final isPercentage = institution.gradingSystem == GradingSystemType.knustCwa;
    final metricLabel = isPercentage ? 'Cumulative CWA' : 'Cumulative GPA';

    if (grades.isEmpty) {
      return AcademicMetricResult(
        scoreValue: 0,
        formattedScore: isPercentage ? '0.00% CWA' : '0.00 / 4.00',
        honoursClass: 'No Data',
        honoursColor: _noDataColor,
        totalCredits: 0,
        isPercentage: isPercentage,
        metricLabel: metricLabel,
        statusSummary: 'Add courses to compute your ${isPercentage ? 'CWA' : 'GPA'}',
      );
    }

    var totalCredits = 0;
    var totalWeightedPoints = 0.0;
    for (final grade in grades) {
      final credits = _credits(grade);
      totalCredits += credits;
      totalWeightedPoints += credits * _pointForScore(grade.score, institution.gradingSystem);
    }

    final calculatedScore = totalCredits > 0 ? totalWeightedPoints / totalCredits : 0.0;
    final levels = levelTotals(grades, institution);
    final fgpa = levels == null ? null : weightedLevelAverage(levels, institution.levelWeights);
    final honours = classify(fgpa ?? calculatedScore, institution);

    final formatted = isPercentage
        ? '${calculatedScore.toStringAsFixed(2)}% CWA'
        : '${calculatedScore.toStringAsFixed(2)} / ${maxScaleFor(institution.gradingSystem).toStringAsFixed(2)}';

    return AcademicMetricResult(
      scoreValue: calculatedScore,
      formattedScore: formatted,
      honoursClass: honours.title,
      honoursColor: honours.color,
      totalCredits: totalCredits,
      isPercentage: isPercentage,
      metricLabel: metricLabel,
      statusSummary: '${honours.title} • $totalCredits Total Credit Hours',
      fgpa: fgpa,
    );
  }
}
