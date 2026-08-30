class Course {
  Course({
    required this.courseId,
    required this.courseCode,
    required this.courseTitle,
    required this.lecturer,
    required this.creditHours,
  });

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        courseId: json['courseId'] as int,
        courseCode: json['courseCode'] as String,
        courseTitle: json['courseTitle'] as String,
        lecturer: json['lecturer'] as String,
        creditHours: json['creditHours'] as int,
      );

  final int courseId;
  final String courseCode;
  final String courseTitle;
  final String lecturer;
  final int creditHours;

  String get label => '$courseCode · $courseTitle';
}
