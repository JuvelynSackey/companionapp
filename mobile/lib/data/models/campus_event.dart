class CampusEvent {
  CampusEvent({
    required this.eventId,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.location,
    required this.clubName,
    required this.attendeeCount,
    required this.isRegistered,
    this.createdBy,
  });

  factory CampusEvent.fromJson(Map<String, dynamic> json) => CampusEvent(
        eventId: json['eventId'] as int,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        eventDate: DateTime.parse(json['eventDate'] as String),
        location: json['location'] as String?,
        clubName: json['clubName'] as String?,
        attendeeCount: json['attendeeCount'] as int,
        // The backend can return null here (LEFT JOIN with no match) instead of false.
        isRegistered: json['isRegistered'] as bool? ?? false,
        createdBy: json['createdBy'] as int?,
      );

  final int eventId;
  final String title;
  final String description;
  final DateTime eventDate;
  final String? location;
  final String? clubName;
  final int attendeeCount;
  final bool isRegistered;

  /// User id of whoever created the event; null when unknown (the creating
  /// account was deleted, or an older server that does not send it).
  final int? createdBy;
}
