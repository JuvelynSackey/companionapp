import '../../core/utils/course_code.dart';

const dayNames =['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

/// Now a locally-owned, student-managed model (no backend authority — see
/// LocalScheduleRepository). scheduleId is a locally-generated id, not a
/// backend row id; toJson()/fromJson() here are for local persistence, not
/// the (now-unused) GET /api/schedule response shape, though the field
/// names are kept identical since nothing about the shape needed to change.
class ScheduleEntry {
  /// Every way an entry is made (added, edited, imported, loaded from the
  /// device) passes through here, so the course code is always in the
  /// University's printed form ("DCIT 103") and a blank room is "no room".
  ScheduleEntry({
    required this.scheduleId,
    required String courseCode,
    required this.courseTitle,
    required this.lecturer,
    required this.dayOfWeek,
    required this.dayName,
    required this.startTime,
    required this.endTime,
    required String? room,
  })  : courseCode = normalizeCourseCode(courseCode),
        room = (room == null || room.trim().isEmpty) ? null : room.trim();

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) => ScheduleEntry(
        scheduleId: json['scheduleId'] as int,
        courseCode: json['courseCode'] as String,
        courseTitle: json['courseTitle'] as String,
        lecturer: json['lecturer'] as String,
        dayOfWeek: json['dayOfWeek'] as int,
        dayName: json['dayName'] as String,
        startTime: json['startTime'] as String,
        endTime: json['endTime'] as String,
        room: json['room'] as String?,
      );

  factory ScheduleEntry.create({
    required int scheduleId,
    required String courseCode,
    required String courseTitle,
    required String lecturer,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? room,
  }) =>
      ScheduleEntry(
        scheduleId: scheduleId,
        courseCode: courseCode,
        courseTitle: courseTitle,
        lecturer: lecturer,
        dayOfWeek: dayOfWeek,
        dayName: dayNames[dayOfWeek],
        startTime: startTime,
        endTime: endTime,
        room: room,
      );

  final int scheduleId;
  final String courseCode;
  final String courseTitle;
  final String lecturer;
  final int dayOfWeek; // 1 = Monday .. 7 = Sunday
  final String dayName;
  final String startTime;
  final String endTime;
  final String? room;

  Map<String, dynamic> toJson() => {
        'scheduleId': scheduleId,
        'courseCode': courseCode,
        'courseTitle': courseTitle,
        'lecturer': lecturer,
        'dayOfWeek': dayOfWeek,
        'dayName': dayName,
        'startTime': startTime,
        'endTime': endTime,
        'room': room,
      };

  ScheduleEntry copyWith({
    String? courseCode,
    String? courseTitle,
    String? lecturer,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    String? room,
  }) =>
      ScheduleEntry.create(
        scheduleId: scheduleId,
        courseCode: courseCode ?? this.courseCode,
        courseTitle: courseTitle ?? this.courseTitle,
        lecturer: lecturer ?? this.lecturer,
        dayOfWeek: dayOfWeek ?? this.dayOfWeek,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        room: room ?? this.room,
      );
}
