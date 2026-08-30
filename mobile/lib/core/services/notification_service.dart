import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
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
      id: 0x40000000 | (exam.id.hashCode & 0x3fffffff), // keep exam ids out of the schedule-id range above
      title: 'Exam reminder: ${exam.courseCode}',
      body: '${exam.courseTitle} at ${exam.venue} — starts ${exam.startTime} on ${exam.examDate}',
      scheduledDate: tz.TZDateTime.from(reminderTime, tz.local),
      notificationDetails: const NotificationDetails(android: _examChannel, iOS: DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelClassReminder(int scheduleId) => _plugin.cancel(id: scheduleId);

  Future<void> cancelExamReminder(String examId) => _plugin.cancel(id: 0x40000000 | (examId.hashCode & 0x3fffffff));

  Future<void> cancelAll() => _plugin.cancelAll();
}
