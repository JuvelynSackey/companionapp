class DashboardStats {
  DashboardStats({
    required this.classesToday,
    required this.announcements,
    required this.upcomingEvents,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        classesToday: json['classesToday'] as int,
        announcements: json['announcements'] as int,
        upcomingEvents: json['upcomingEvents'] as int,
      );

  final int classesToday;
  final int announcements;
  final int upcomingEvents;
}

class TodayClass {
  TodayClass({
    required this.scheduleId,
    required this.courseTitle,
    required this.lecturer,
    required this.room,
    required this.startTime,
    required this.endTime,
    required this.inProgress,
  });

  factory TodayClass.fromJson(Map<String, dynamic> json) => TodayClass(
        scheduleId: json['scheduleId'] as int,
        courseTitle: json['courseTitle'] as String,
        lecturer: json['lecturer'] as String,
        room: json['room'] as String?,
        startTime: json['startTime'] as String,
        endTime: json['endTime'] as String,
        inProgress: json['inProgress'] as bool,
      );

  final int scheduleId;
  final String courseTitle;
  final String lecturer;
  final String? room;
  final String startTime;
  final String endTime;
  final bool inProgress;
}

class DashboardAnnouncementSummary {
  DashboardAnnouncementSummary({
    required this.announcementId,
    required this.title,
    required this.message,
    required this.category,
    required this.datePosted,
  });

  factory DashboardAnnouncementSummary.fromJson(Map<String, dynamic> json) =>
      DashboardAnnouncementSummary(
        announcementId: json['announcementId'] as int,
        title: json['title'] as String,
        message: json['message'] as String,
        category: json['category'] as String,
        datePosted: DateTime.parse(json['datePosted'] as String),
      );

  final int announcementId;
  final String title;
  final String message;
  final String category;
  final DateTime datePosted;
}

class UpcomingEventSummary {
  UpcomingEventSummary({
    required this.eventId,
    required this.title,
    required this.eventDate,
    required this.location,
  });

  factory UpcomingEventSummary.fromJson(Map<String, dynamic> json) => UpcomingEventSummary(
        eventId: json['eventId'] as int,
        title: json['title'] as String,
        eventDate: DateTime.parse(json['eventDate'] as String),
        location: json['location'] as String?,
      );

  final int eventId;
  final String title;
  final DateTime eventDate;
  final String? location;
}

class DashboardData {
  DashboardData({
    required this.stats,
    required this.todaysClasses,
    required this.announcements,
    required this.upcomingEvents,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
        stats: DashboardStats.fromJson(json['stats'] as Map<String, dynamic>),
        todaysClasses: (json['todaysClasses'] as List)
            .map((e) => TodayClass.fromJson(e as Map<String, dynamic>))
            .toList(),
        announcements: (json['announcements'] as List)
            .map((e) => DashboardAnnouncementSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
        upcomingEvents: (json['upcomingEvents'] as List)
            .map((e) => UpcomingEventSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final DashboardStats stats;
  final List<TodayClass> todaysClasses;
  final List<DashboardAnnouncementSummary> announcements;
  final List<UpcomingEventSummary> upcomingEvents;
}
