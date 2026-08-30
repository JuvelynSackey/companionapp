class Announcement {
  Announcement({
    required this.announcementId,
    required this.title,
    required this.message,
    required this.category,
    required this.postedBy,
    required this.datePosted,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        announcementId: json['announcementId'] as int,
        title: json['title'] as String,
        message: json['message'] as String,
        category: json['category'] as String,
        postedBy: json['postedBy'] as String?,
        datePosted: DateTime.parse(json['datePosted'] as String),
      );

  final int announcementId;
  final String title;
  final String message;
  final String category; // general | academic | emergency
  final String? postedBy;
  final DateTime datePosted;
}
