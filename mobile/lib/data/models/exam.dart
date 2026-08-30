/// Local-only model — the backend has no exams table/endpoint.
/// Ported from app/src/main/java/com/example/data/local/entity/Entities.kt (ExamScheduleEntity).
class Exam {
  Exam({
    required this.id,
    required this.courseCode,
    required this.courseTitle,
    required this.examDate,
    required this.startTime,
    required this.endTime,
    required this.venue,
    this.seatRange = '',
    this.invigilator = '',
    this.walkingTimeMinutes = 15,
    this.rules = 'Calculators permitted. No mobile phones or smartwatches. Bring Student ID Card.',
  });

  factory Exam.fromJson(Map<String, dynamic> json) => Exam(
        id: json['id'] as String,
        courseCode: json['courseCode'] as String,
        courseTitle: json['courseTitle'] as String,
        examDate: json['examDate'] as String,
        startTime: json['startTime'] as String,
        endTime: json['endTime'] as String,
        venue: json['venue'] as String,
        seatRange: json['seatRange'] as String? ?? '',
        invigilator: json['invigilator'] as String? ?? '',
        walkingTimeMinutes: json['walkingTimeMinutes'] as int? ?? 15,
        rules: json['rules'] as String? ?? '',
      );

  final String id;
  final String courseCode;
  final String courseTitle;
  final String examDate; // ISO "yyyy-MM-dd"
  final String startTime; // "HH:mm"
  final String endTime;
  final String venue;
  final String seatRange;
  final String invigilator;
  final int walkingTimeMinutes;
  final String rules;

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseCode': courseCode,
        'courseTitle': courseTitle,
        'examDate': examDate,
        'startTime': startTime,
        'endTime': endTime,
        'venue': venue,
        'seatRange': seatRange,
        'invigilator': invigilator,
        'walkingTimeMinutes': walkingTimeMinutes,
        'rules': rules,
      };

  Exam copyWith({
    String? courseCode,
    String? courseTitle,
    String? examDate,
    String? startTime,
    String? endTime,
    String? venue,
    String? seatRange,
    String? invigilator,
    int? walkingTimeMinutes,
    String? rules,
  }) =>
      Exam(
        id: id,
        courseCode: courseCode ?? this.courseCode,
        courseTitle: courseTitle ?? this.courseTitle,
        examDate: examDate ?? this.examDate,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        venue: venue ?? this.venue,
        seatRange: seatRange ?? this.seatRange,
        invigilator: invigilator ?? this.invigilator,
        walkingTimeMinutes: walkingTimeMinutes ?? this.walkingTimeMinutes,
        rules: rules ?? this.rules,
      );
}
