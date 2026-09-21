import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/services/announcement_push_bridge.dart';
import 'package:mobile/core/services/push_coordinator.dart';

import 'support/push_fakes.dart';

/// The announcement poll and real push must not both notify: while this device
/// is registered for push the poll only keeps the cursor moving, and when push
/// is not working the poll notifies exactly as it did before push existed.
Future<({FakeNotificationService notifications, FakeAnnouncementApiForPush api})> _runPoll({
  required bool pushActive,
  required int cursor,
  required List<int> ids,
}) async {
  final notifications = FakeNotificationService();
  final api = FakeAnnouncementApiForPush(cursor: cursor, items: [for (final id in ids) announcement(id)]);
  final container = ProviderContainer(overrides: [
    announcementApiProvider.overrideWithValue(api),
    notificationServiceProvider.overrideWithValue(notifications),
  ]);
  addTearDown(container.dispose);
  container.read(pushActiveProvider.notifier).state = pushActive;

  final bridge = container.read(announcementPushBridgeProvider);
  bridge.start(interval: const Duration(hours: 1));
  await pumpEventQueue();
  bridge.stop();

  return (notifications: notifications, api: api);
}

void main() {
  group('push not active (not set up, refused, or registration failed)', () {
    test('new announcements are notified, as before push existed', () async {
      final run = await _runPoll(pushActive: false, cursor: 3, ids: [5, 4, 3, 2]);

      expect(run.notifications.announcements.map((a) => a.announcementId).toSet(), {4, 5});
      expect(run.api.cursorUpdates, [5]);
    });

    test('nothing new means nothing shown and the cursor is not touched', () async {
      final run = await _runPoll(pushActive: false, cursor: 5, ids: [5, 4]);

      expect(run.notifications.announcements, isEmpty);
      expect(run.api.cursorUpdates, isEmpty);
    });
  });

  group('push active (this device is registered)', () {
    test('the poll does not notify, so the same announcement is not shown twice', () async {
      final run = await _runPoll(pushActive: true, cursor: 3, ids: [5, 4, 3]);

      expect(run.notifications.announcements, isEmpty);
    });

    test('but it still moves the cursor forward, so switching push off later does not replay old alerts', () async {
      final run = await _runPoll(pushActive: true, cursor: 3, ids: [5, 4, 3]);

      expect(run.api.cursorUpdates, [5]);
    });
  });

  group('first ever sync (cursor 0)', () {
    test('baselines without notifying, whether or not push is active', () async {
      for (final active in [false, true]) {
        final run = await _runPoll(pushActive: active, cursor: 0, ids: [3, 2, 1]);

        expect(run.notifications.announcements, isEmpty, reason: 'active=$active');
        expect(run.api.cursorUpdates, [3], reason: 'active=$active');
      }
    });
  });
}
