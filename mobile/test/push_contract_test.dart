import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/services/notification_service.dart';
import 'package:mobile/core/services/push_coordinator.dart';
import 'package:mobile/core/services/push_messaging.dart';
import 'package:mobile/core/services/push_bootstrap.dart';
import 'package:mobile/data/repositories/auth_repository.dart';
import 'package:mobile/data/api/auth_api.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/features/auth/session_controller.dart';

import 'support/admin_fakes.dart';
import 'support/push_fakes.dart';

/// The server (backend/src/services/notificationService.js) and the app agree
/// on a few names that neither can check alone. Read them out of the backend
/// source so a rename on one side fails here instead of silently breaking push.
String _backendSource() {
  for (final path in ['../backend/src/services/notificationService.js', 'backend/src/services/notificationService.js']) {
    final file = File(path);
    if (file.existsSync()) return file.readAsStringSync();
  }
  throw StateError('backend/src/services/notificationService.js not found (run flutter test from mobile/)');
}

String _backendConstant(String source, String name) {
  final match = RegExp("export const $name = '([^']+)'").firstMatch(source);
  if (match == null) throw StateError('$name not found in the backend');
  return match.group(1)!;
}

void main() {
  group('contract with the backend push messages', () {
    final source = _backendSource();

    test('the Android channel ids are the ones the app creates', () {
      expect(_backendConstant(source, 'CHANNEL_ANNOUNCEMENTS'), NotificationService.announcementChannelId);
      expect(_backendConstant(source, 'CHANNEL_EMERGENCY'), NotificationService.emergencyChannelId);
    });

    test('the message data keys and values are the ones PushMessage reads', () {
      expect(source, contains("type: 'announcement'"));
      expect(source, contains('announcementId: String('));
      expect(source, contains('category:'));

      final push = announcementPush(id: 42, category: 'emergency');
      expect(push.isAnnouncement, isTrue);
      expect(push.announcementId, 42);
      expect(push.isEmergency, isTrue);
    });

    test('an emergency title carries the same siren the app puts on its own local notification', () {
      expect(source, contains('🚨 \${title}'));
    });
  });

  group('PushMessage', () {
    test('a plain message is not an announcement', () {
      const message = PushMessage(title: 'Hi', body: 'There');
      expect(message.isAnnouncement, isFalse);
      expect(message.announcementId, isNull);
      expect(message.isEmergency, isFalse);
    });

    test('an unparseable or missing id reads as null, not a crash', () {
      expect(const PushMessage(data: {'announcementId': 'abc'}).announcementId, isNull);
      expect(const PushMessage(data: {}).announcementId, isNull);
      expect(const PushMessage(data: {'announcementId': '12'}).announcementId, 12);
    });
  });

  group('the default (no Firebase) build', () {
    test('NoopPushMessaging is inert', () async {
      const noop = NoopPushMessaging();
      expect(noop.isAvailable, isFalse);
      expect(await noop.requestPermission(), isFalse);
      expect(await noop.getToken(), isNull);
      expect(await noop.getInitialMessage(), isNull);
      expect(await noop.onTokenRefresh.isEmpty, isTrue);
      expect(await noop.onForegroundMessage.isEmpty, isTrue);
      expect(await noop.onMessageOpened.isEmpty, isTrue);
      await noop.deleteToken();
    });

    test('the app\'s default provider is the no-op', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(pushMessagingProvider).isAvailable, isFalse);
    });

    test('without --dart-define=FCM_ENABLED=true, Firebase is never started', () async {
      // (Tests run without the flag.) If this initialised Firebase it would throw
      // or hang here, with no google-services.json.
      final messaging = await createPushMessaging();
      expect(messaging.isAvailable, isFalse);
    });

    test('the push platform is android or ios or web, never anything the server would reject', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect({'android', 'ios', 'web'}, contains(container.read(pushPlatformProvider)));
    });
  });

  group('signing out', () {
    test('unregisters the device while the session is still valid, then clears the login', () async {
      final events = <String>[];
      final push = FakePushMessaging();
      final api = FakeDeviceApi();
      final container = ProviderContainer(overrides: [
        pushMessagingProvider.overrideWithValue(push),
        deviceApiProvider.overrideWithValue(api),
        pushPlatformProvider.overrideWithValue('android'),
        authRepositoryProvider.overrideWithValue(_RecordingAuthRepository(events)),
        sessionControllerProvider.overrideWith(() => FakeSessionController(studentUser)),
      ]);
      addTearDown(container.dispose);
      await container.read(sessionControllerProvider.future);
      await container.read(pushCoordinatorProvider).start();
      api.events.clear();

      await container.read(sessionControllerProvider.notifier).signOut();

      expect(api.events, ['unregister:fcm-token-1']);
      expect(push.tokenDeletions, 1);
      expect(events, ['login cleared']);
      expect(container.read(sessionControllerProvider).valueOrNull, isNull);
    });

    test('unregistering happens BEFORE the login is cleared (it needs the session)', () async {
      final order = <String>[];
      final api = _OrderedDeviceApi(order);
      final container = ProviderContainer(overrides: [
        pushMessagingProvider.overrideWithValue(FakePushMessaging()),
        deviceApiProvider.overrideWithValue(api),
        pushPlatformProvider.overrideWithValue('android'),
        authRepositoryProvider.overrideWithValue(_RecordingAuthRepository(order)),
        sessionControllerProvider.overrideWith(() => FakeSessionController(studentUser)),
      ]);
      addTearDown(container.dispose);
      await container.read(sessionControllerProvider.future);
      await container.read(pushCoordinatorProvider).start();
      order.clear();

      await container.read(sessionControllerProvider.notifier).signOut();

      expect(order, ['server unregister', 'login cleared']);
    });

    test('with push not set up, signing out just clears the login', () async {
      final events = <String>[];
      final container = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(_RecordingAuthRepository(events)),
        sessionControllerProvider.overrideWith(() => FakeSessionController(studentUser)),
      ]);
      addTearDown(container.dispose);
      await container.read(sessionControllerProvider.future);

      await container.read(sessionControllerProvider.notifier).signOut();

      expect(events, ['login cleared']);
    });
  });
}

class _RecordingAuthRepository extends AuthRepository {
  _RecordingAuthRepository(this.events) : super(AuthApi(ApiClient(TokenStorage())), TokenStorage());
  final List<String> events;

  @override
  Future<void> signOut() async => events.add('login cleared');
}

class _OrderedDeviceApi extends FakeDeviceApi {
  _OrderedDeviceApi(this.order);
  final List<String> order;

  @override
  Future<void> unregisterToken(String token) async {
    order.add('server unregister');
    await super.unregisterToken(token);
  }
}
