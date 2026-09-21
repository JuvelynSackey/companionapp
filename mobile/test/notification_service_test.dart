import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/services/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  group('NotificationService.examReminderId', () {
    // Regression test: scheduling the same exam reminder twice (e.g.
    // re-tapping "Remind Me", or re-syncing) must resolve to the same
    // flutter_local_notifications id both times, since zonedSchedule
    // replaces an existing alarm at a given id rather than adding a
    // second one — verified live on-device (dumpsys alarm stayed at 1
    // entry after re-scheduling). A non-deterministic id here would
    // silently reintroduce duplicate alarms.
    test('the same exam id always produces the same notification id', () {
      const examId = 'exam_dcit201_2026';
      expect(NotificationService.examReminderId(examId), NotificationService.examReminderId(examId));
    });

    test('different exam ids produce different notification ids', () {
      expect(
        NotificationService.examReminderId('exam_a'),
        isNot(NotificationService.examReminderId('exam_b')),
      );
    });

    test('the id stays out of the class-reminder id range (which uses raw scheduleIds)', () {
      // Class reminders use small positive ints directly as their id
      // (ScheduleEntry.scheduleId); exam ids must not collide with those.
      expect(NotificationService.examReminderId('exam_1') > 0x3fffffff, isTrue);
    });
  });

  group('NotificationService.announcementNotificationId', () {
    test('the same announcement id always produces the same notification id', () {
      expect(NotificationService.announcementNotificationId(42), NotificationService.announcementNotificationId(42));
    });

    test('different announcement ids produce different notification ids', () {
      expect(
        NotificationService.announcementNotificationId(1),
        isNot(NotificationService.announcementNotificationId(2)),
      );
    });

    test('the id range does not overlap examReminderId\'s tagged range', () {
      // examReminderId tags with 0x40000000; announcementNotificationId must
      // stay below that so re-notifying an announcement can never collide
      // with an exam reminder's alarm.
      for (final id in [1, 42, 999999]) {
        expect(NotificationService.announcementNotificationId(id) & 0x40000000, 0);
      }
    });

    test('the id stays out of the class-reminder id range (which uses raw scheduleIds)', () {
      expect(NotificationService.announcementNotificationId(1) > 0x1fffffff, isTrue);
    });
  });

  // Regression test for a real native-only bug: NotificationService imported
  // timezone/data/latest.dart (the size-reduced dataset), which prunes zones
  // whose rules are identical to another canonical zone as duplicates.
  // Africa/Accra (UTC+0, no DST) is one of those pruned duplicates, so
  // tz.getLocation('Africa/Accra') threw at runtime the first time a
  // reminder was scheduled on a real device — Chrome web testing never
  // caught it because flutter_local_notifications no-ops entirely on web.
  // latest_all.dart includes every zone, Accra included.
  test('Africa/Accra resolves via the timezone data NotificationService actually uses', () {
    tz_data.initializeTimeZones();
    expect(() => tz.getLocation('Africa/Accra'), returnsNormally);

    final accra = tz.getLocation('Africa/Accra');
    expect(accra.currentTimeZone.offset, Duration.zero); // UTC+0, no DST
  });
}
