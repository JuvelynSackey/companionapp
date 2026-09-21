import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/services/push_coordinator.dart';
import 'package:mobile/core/services/push_messaging.dart';
import 'package:mobile/features/alerts/alerts_providers.dart';
import 'package:mobile/features/shell/nav_providers.dart';

import 'support/push_fakes.dart';

class _Env {
  _Env({PushMessaging? messaging})
      : push = messaging ?? FakePushMessaging(),
        api = FakeDeviceApi(),
        notifications = FakeNotificationService(),
        announcementApi = FakeAnnouncementApiForPush() {
    container = ProviderContainer(overrides: [
      pushMessagingProvider.overrideWithValue(push),
      deviceApiProvider.overrideWithValue(api),
      notificationServiceProvider.overrideWithValue(notifications),
      announcementApiProvider.overrideWithValue(announcementApi),
      pushPlatformProvider.overrideWithValue('android'),
    ]);
  }

  final PushMessaging push;
  final FakeDeviceApi api;
  final FakeNotificationService notifications;
  final FakeAnnouncementApiForPush announcementApi;
  late final ProviderContainer container;

  FakePushMessaging get fake => push as FakePushMessaging;
  PushCoordinator get coordinator => container.read(pushCoordinatorProvider);
  bool get active => container.read(pushActiveProvider);
  AppTab get tab => container.read(selectedTabProvider);
}

_Env _env({PushMessaging? messaging}) {
  final env = _Env(messaging: messaging);
  addTearDown(env.container.dispose);
  return env;
}

void main() {
  group('start', () {
    test('asks permission, registers this device\'s token with its platform, and becomes active', () async {
      final env = _env();

      await env.coordinator.start();

      expect(env.fake.permissionRequests, 1);
      expect(env.api.registered, [(token: 'fcm-token-1', platform: 'android')]);
      expect(env.active, isTrue);
    });

    test('does nothing at all when push is not set up (the default build)', () async {
      final env = _env(messaging: const NoopPushMessaging());

      await env.coordinator.start();

      expect(env.api.events, isEmpty);
      expect(env.active, isFalse);
    });

    test('permission refused: no registration, not active, no listeners left behind', () async {
      final env = _env(messaging: FakePushMessaging(permissionGranted: false));

      await env.coordinator.start();

      expect(env.api.events, isEmpty);
      expect(env.active, isFalse);
      expect(env.fake.hasListeners, isFalse);
    });

    test('a token that cannot be obtained is not registered', () async {
      final env = _env(messaging: FakePushMessaging(token: null));

      await env.coordinator.start();

      expect(env.api.events, isEmpty);
      expect(env.active, isFalse);
    });

    test('calling start again while running does not register twice', () async {
      final env = _env();

      await env.coordinator.start();
      await env.coordinator.start();

      expect(env.api.registered.length, 1);
      expect(env.fake.permissionRequests, 1);
    });

    test('if the server cannot be reached, push stays inactive (so the poll keeps notifying) and nothing throws', () async {
      final env = _env();
      env.api.registerError = ApiException('Could not reach the server.');

      await env.coordinator.start();

      expect(env.active, isFalse);
    });

    test('registration that failed at launch succeeds when the token later refreshes', () async {
      final env = _env();
      env.api.registerError = ApiException('offline');
      await env.coordinator.start();
      expect(env.active, isFalse);

      env.api.registerError = null;
      env.fake.emitTokenRefresh('fcm-token-2');
      await pumpEventQueue();

      expect(env.api.registered.single.token, 'fcm-token-2');
      expect(env.active, isTrue);
    });

    test('a rotated token is registered', () async {
      final env = _env();
      await env.coordinator.start();

      env.fake.emitTokenRefresh('fcm-token-2');
      await pumpEventQueue();

      expect(env.api.registered.map((r) => r.token), ['fcm-token-1', 'fcm-token-2']);
    });

    test('an unexpected error while starting is contained', () async {
      final fake = FakePushMessaging();
      final env = _env(messaging: _ThrowingMessaging(fake));

      await expectLater(env.coordinator.start(), completes);
      expect(env.active, isFalse);
    });
  });

  group('a message while the app is open', () {
    test('an announcement is shown as a notification, with the server\'s title and the right urgency', () async {
      final env = _env();
      await env.coordinator.start();

      env.fake.emitForeground(announcementPush(id: 7, title: '🚨 Campus closed', body: 'Severe weather', category: 'emergency'));
      await pumpEventQueue();

      expect(env.notifications.pushed, [(id: 7, title: '🚨 Campus closed', body: 'Severe weather', isEmergency: true)]);
    });

    test('a normal announcement is not marked as an emergency', () async {
      final env = _env();
      await env.coordinator.start();

      env.fake.emitForeground(announcementPush(category: 'academic'));
      await pumpEventQueue();

      expect(env.notifications.pushed.single.isEmergency, isFalse);
    });

    test('it also refreshes the Alerts list', () async {
      final env = _env();
      env.container.listen(announcementsProvider, (_, _) {});
      await env.container.read(announcementsProvider.future);
      final before = env.announcementApi.fetchCount;
      await env.coordinator.start();

      env.fake.emitForeground(announcementPush());
      await pumpEventQueue();

      expect(env.announcementApi.fetchCount, greaterThan(before));
    });

    test('a message that is not an announcement shows nothing (but still refreshes)', () async {
      final env = _env();
      await env.coordinator.start();

      env.fake.emitForeground(const PushMessage(title: 'Hello', body: 'World', data: {'type': 'something-else'}));
      await pumpEventQueue();

      expect(env.notifications.pushed, isEmpty);
    });

    test('an announcement with no usable id shows nothing rather than a broken notification', () async {
      final env = _env();
      await env.coordinator.start();

      env.fake.emitForeground(const PushMessage(title: 'T', body: 'B', data: {'type': 'announcement', 'announcementId': 'abc'}));
      await pumpEventQueue();

      expect(env.notifications.pushed, isEmpty);
    });

    test('a missing title or body falls back to sensible text', () async {
      final env = _env();
      await env.coordinator.start();

      env.fake.emitForeground(const PushMessage(data: {'type': 'announcement', 'announcementId': '3'}));
      await pumpEventQueue();

      expect(env.notifications.pushed.single.title, 'New announcement');
      expect(env.notifications.pushed.single.body, '');
    });

    test('failing to show the notification does not break message handling', () async {
      final env = _env();
      env.notifications.pushError = Exception('plugin unavailable');
      await env.coordinator.start();

      env.fake.emitForeground(announcementPush());
      await pumpEventQueue();

      // still alive: a second message is handled
      env.notifications.pushError = null;
      env.fake.emitForeground(announcementPush(id: 8));
      await pumpEventQueue();
      expect(env.notifications.pushed.single.id, 8);
    });
  });

  group('tapping a notification', () {
    test('while the app was in the background opens the Alerts tab', () async {
      final env = _env();
      await env.coordinator.start();
      expect(env.tab, AppTab.dashboard);

      env.fake.emitOpened(announcementPush());
      await pumpEventQueue();

      expect(env.tab, AppTab.alerts);
    });

    test('that launched the app from closed opens the Alerts tab', () async {
      final env = _env(messaging: FakePushMessaging()..initialMessage = announcementPush());

      await env.coordinator.start();

      expect(env.tab, AppTab.alerts);
    });

    test('with no launching notification the tab is left alone', () async {
      final env = _env();

      await env.coordinator.start();

      expect(env.tab, AppTab.dashboard);
    });
  });

  group('stop and sign-out', () {
    test('stop ends the listeners and marks push inactive, without telling the server', () async {
      final env = _env();
      await env.coordinator.start();

      env.coordinator.stop();
      env.fake.emitForeground(announcementPush());
      env.fake.emitTokenRefresh('fcm-token-2');
      await pumpEventQueue();

      expect(env.active, isFalse);
      expect(env.fake.hasListeners, isFalse);
      expect(env.notifications.pushed, isEmpty);
      expect(env.api.unregistered, isEmpty);
      expect(env.api.registered.length, 1, reason: 'the refresh after stop was ignored');
    });

    test('start works again after stop (signing back in)', () async {
      final env = _env();
      await env.coordinator.start();
      env.coordinator.stop();

      await env.coordinator.start();

      expect(env.api.registered.length, 2);
      expect(env.active, isTrue);
    });

    test('unregisterCurrentDevice tells the server, forgets the token, and goes inactive', () async {
      final env = _env();
      await env.coordinator.start();

      await env.coordinator.unregisterCurrentDevice();

      expect(env.api.unregistered, ['fcm-token-1']);
      expect(env.fake.tokenDeletions, 1);
      expect(env.active, isFalse);
      expect(env.fake.hasListeners, isFalse);
    });

    test('if the server cannot be told, the local token is still deleted and it does not throw', () async {
      final env = _env();
      await env.coordinator.start();
      env.api.unregisterError = ApiException('offline');

      await expectLater(env.coordinator.unregisterCurrentDevice(), completes);

      expect(env.fake.tokenDeletions, 1);
      expect(env.active, isFalse);
    });

    test('if deleting the local token fails, it still completes', () async {
      final env = _env();
      await env.coordinator.start();
      env.fake.deleteTokenError = Exception('boom');

      await expectLater(env.coordinator.unregisterCurrentDevice(), completes);

      expect(env.api.unregistered, ['fcm-token-1']);
    });

    test('when push was never registered there is nothing to tell the server', () async {
      final env = _env(messaging: FakePushMessaging(permissionGranted: false));
      await env.coordinator.start();

      await env.coordinator.unregisterCurrentDevice();

      expect(env.api.unregistered, isEmpty);
    });

    test('when push is not set up at all, signing out touches nothing', () async {
      final env = _env(messaging: const NoopPushMessaging());

      await env.coordinator.unregisterCurrentDevice();

      expect(env.api.events, isEmpty);
    });
  });
}

/// A transport whose token lookup blows up, to check start() contains failures.
class _ThrowingMessaging extends FakePushMessaging {
  _ThrowingMessaging(FakePushMessaging base) : super(available: base.available);

  @override
  Future<String?> getToken() async => throw StateError('no play services');
}
