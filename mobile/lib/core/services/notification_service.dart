import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// latest.dart (not latest_all.dart) prunes zones whose rules are identical
// to another canonical zone as duplicates — Africa/Accra is one of those
// (UTC+0, no DST, same as several others) and isn't included, which threw
// `Location with the name "Africa/Accra" doesn't exist` at runtime on a
// real device the first time a reminder was scheduled.
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../../data/models/announcement.dart';
import '../../data/models/exam.dart';
import '../../data/models/schedule_entry.dart';
import '../utils/schedule_time_math.dart';

/// Wraps flutter_local_notifications for class/exam reminders. Every
/// institution in this app is in Ghana (single timezone, no DST), so the
/// local zone is hardcoded to Africa/Accra rather than pulling in a device
/// timezone-detection package for a single-country app.
///
/// Note: this plugin has no dedicated web implementation registered in
/// this project (no flutter_local_notifications_web dependency), so on web
/// every call below resolves to a safe no-op internally (the plugin's own
/// kIsWeb-guarded platform resolution returns null) — it will not throw,
/// but it also won't schedule anything. Real scheduling only happens on
/// Android/iOS/desktop.
class NotificationService {
  NotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const _classChannel = AndroidNotificationDetails(
    'class_reminders',
    'Class Reminders',
    channelDescription: 'Reminders before your scheduled classes',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const _examChannel = AndroidNotificationDetails(
    'exam_reminders',
    'Exam Reminders',
    channelDescription: 'Reminders before your scheduled exams',
    importance: Importance.high,
    priority: Priority.high,
  );

  /// Android channel ids. The server names these in its push messages
  /// (backend/src/services/notificationService.js), so the two must match.
  static const announcementChannelId = 'announcements';
  static const emergencyChannelId = 'emergency_announcements';

  static const _announcementChannel = AndroidNotificationDetails(
    announcementChannelId,
    'Campus Announcements',
    channelDescription: 'New posts to the campus notice board',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const _emergencyChannel = AndroidNotificationDetails(
    emergencyChannelId,
    'Emergency Announcements',
    channelDescription: 'Urgent, time-critical campus alerts',
    importance: Importance.max,
    priority: Priority.max,
  );

  /// Deterministic notification id for a given exam — the same exam always
  /// maps to the same id, so re-scheduling (e.g. tapping "Remind Me" again,
  /// or re-syncing) replaces the existing OS-level alarm instead of adding
  /// a duplicate. Kept out of the class-reminder id range (which uses the
  /// schedule's own int id directly) via the high bit.
  static int examReminderId(String examId) => 0x40000000 | (examId.hashCode & 0x3fffffff);

  /// Deterministic notification id for an announcement, tagged into its own
  /// bit range (below examReminderId's 0x40000000 tag, above the raw
  /// schedule ids used directly as class-reminder ids) so re-notifying the
  /// same announcement replaces rather than duplicates.
  static int announcementNotificationId(int announcementId) => 0x20000000 | (announcementId & 0x1fffffff);

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Accra'));

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
        macOS: DarwinInitializationSettings(),
      ),
    );

    // Create the announcement channels up front. A push that arrives while the
    // app is closed is shown by Android itself, into the channel the server
    // names; if that channel did not exist yet it would land in a default one
    // with the wrong importance (an emergency alert must not be silent).
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      announcementChannelId,
      'Campus Announcements',
      description: 'New posts to the campus notice board',
      importance: Importance.high,
    ));
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      emergencyChannelId,
      'Emergency Announcements',
      description: 'Urgent, time-critical campus alerts',
      importance: Importance.max,
    ));
    _initialized = true;
  }

  /// Returns whether permission was granted (best-effort — some platforms
  /// don't report a result, in which case this assumes granted).
  Future<bool> requestPermission() async {
    final androidGranted = await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    final iosGranted = await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return (androidGranted ?? true) && (iosGranted ?? true);
  }

  /// Schedules a weekly-repeating reminder [minutesBefore] a class starts.
  /// Uses ScheduleEntry.scheduleId as the notification id, so re-syncing
  /// (calling this again after data changes) naturally replaces the old one.
  Future<void> scheduleClassReminder(ScheduleEntry entry, {int minutesBefore = 15}) async {
    await initialize();
    final classStart = ScheduleTimeMath.nextOccurrenceOf(entry.dayOfWeek, entry.startTime);
    final reminderTime = classStart.subtract(Duration(minutes: minutesBefore));
    final scheduled = reminderTime.isBefore(DateTime.now()) ? reminderTime.add(const Duration(days: 7)) : reminderTime;

    await _plugin.zonedSchedule(
      id: entry.scheduleId,
      title: '${entry.courseCode} starts in $minutesBefore minutes',
      body: '${entry.courseTitle} @ ${entry.room ?? 'TBA'}',
      scheduledDate: tz.TZDateTime.from(scheduled, tz.local),
      notificationDetails: const NotificationDetails(android: _classChannel, iOS: DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Schedules a one-off reminder [before] an exam starts (default 24h).
  Future<void> scheduleExamReminder(Exam exam, {Duration before = const Duration(hours: 24)}) async {
    await initialize();
    final examStart = ScheduleTimeMath.combine(DateTime.parse(exam.examDate), exam.startTime);
    final reminderTime = examStart.subtract(before);
    if (reminderTime.isBefore(DateTime.now())) return; // already past — nothing to schedule

    await _plugin.zonedSchedule(
      id: examReminderId(exam.id),
      title: 'Exam reminder: ${exam.courseCode}',
      body: '${exam.courseTitle} at ${exam.venue} — starts ${exam.startTime} on ${exam.examDate}',
      scheduledDate: tz.TZDateTime.from(reminderTime, tz.local),
      notificationDetails: const NotificationDetails(android: _examChannel, iOS: DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Surfaces a campus announcement as a local notification. This is
  /// deliberately the *only* place that turns an announcement into a shown
  /// notification — whether it arrives from AnnouncementPushBridge's
  /// foreground poll (today) or, once a Firebase project is configured (see
  /// PROJECT_AUDIT.md — no google-services.json exists yet), from a real
  /// FCM onMessage/onBackgroundMessage handler, both call this same method
  /// rather than building their own notification. Swapping in real push
  /// later only means replacing the poll with an FCM listener.
  Future<void> showAnnouncementNotification(Announcement announcement) {
    final isEmergency = announcement.category == 'emergency';
    return showPushAnnouncement(
      announcementId: announcement.announcementId,
      title: isEmergency ? '🚨 ${announcement.title}' : announcement.title,
      body: announcement.message,
      isEmergency: isEmergency,
    );
  }

  /// The same notification, built from a push message that arrived while the
  /// app was open (the server already put the 🚨 in an emergency's title). It
  /// shares the id scheme with [showAnnouncementNotification], so if both the
  /// push and the poll surface one announcement, the OS shows it once.
  Future<void> showPushAnnouncement({
    required int announcementId,
    required String title,
    required String body,
    required bool isEmergency,
  }) async {
    await initialize();
    await _plugin.show(
      id: announcementNotificationId(announcementId),
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: isEmergency ? _emergencyChannel : _announcementChannel,
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> cancelClassReminder(int scheduleId) => _plugin.cancel(id: scheduleId);

  Future<void> cancelExamReminder(String examId) => _plugin.cancel(id: examReminderId(examId));

  Future<void> cancelAll() => _plugin.cancelAll();
}
