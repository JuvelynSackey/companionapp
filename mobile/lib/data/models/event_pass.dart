/// Local-only — the backend's /api/events has no pass/ticket concept, just
/// registration rows. Generated client-side right after a successful RSVP
/// and kept around so the student can re-view it later; not a real
/// cryptographically-verifiable credential, just a display artifact.
class EventPass {
  const EventPass({
    required this.passId,
    required this.eventId,
    required this.eventTitle,
    required this.studentName,
    required this.studentId,
    required this.venue,
    required this.eventDate,
  });

  factory EventPass.fromJson(Map<String, dynamic> json) => EventPass(
        passId: json['passId'] as String,
        eventId: json['eventId'] as int,
        eventTitle: json['eventTitle'] as String,
        studentName: json['studentName'] as String,
        studentId: json['studentId'] as String,
        venue: json['venue'] as String?,
        eventDate: DateTime.parse(json['eventDate'] as String),
      );

  final String passId;
  final int eventId;
  final String eventTitle;
  final String studentName;
  final String studentId;
  final String? venue;
  final DateTime eventDate;

  String get qrPayload => 'EVENTPASS|$eventId|$studentId|$passId';

  Map<String, dynamic> toJson() => {
        'passId': passId,
        'eventId': eventId,
        'eventTitle': eventTitle,
        'studentName': studentName,
        'studentId': studentId,
        'venue': venue,
        'eventDate': eventDate.toIso8601String(),
      };
}
