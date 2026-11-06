/// Matches GET /api/grades' per-course shape. `letterGrade` and `passed` are
/// the backend's University of Ghana labels (`passed` is false for E and F,
/// i.e. below 50) — display only. The GPA/CWA number
/// shown to the user is computed institution-aware by AcademicEngine from
/// `score`.
class CourseGrade {
  CourseGrade({
    required this.gradeId,
    required this.courseCode,
    required this.courseTitle,
    required this.creditHours,
    required this.score,
    required this.letterGrade,
    required this.semester,
    required this.passed,
    this.selfReported = false,
  });

  factory CourseGrade.fromJson(Map<String, dynamic> json) => CourseGrade(
        gradeId: json['gradeId'] as int,
        courseCode: json['courseCode'] as String,
        courseTitle: json['courseTitle'] as String,
        creditHours: json['creditHours'] as int,
        score: (json['score'] as num).toDouble(),
        letterGrade: json['letterGrade'] as String,
        semester: json['semester'] as String,
        passed: json['passed'] as bool,
        selfReported: json['selfReported'] as bool? ?? false,
      );

  final int gradeId;
  final String courseCode;
  final String courseTitle;
  final int creditHours;
  final double score;
  final String letterGrade;
  final String semester;
  final bool passed;

  /// The student entered this result themselves; it is not an official record.
  final bool selfReported;
}
