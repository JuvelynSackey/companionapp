import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/services/push_coordinator.dart';
import 'package:mobile/core/services/push_messaging.dart';
import 'package:mobile/data/models/notification_preferences.dart';
import 'package:mobile/features/alerts/push_settings.dart';

import 'support/push_fakes.dart';

Widget _app(FakeDeviceApi api, {PushMessaging? messaging, bool active = false}) => ProviderScope(
      overrides: [
        deviceApiProvider.overrideWithValue(api),
        pushMessagingProvider.overrideWithValue(messaging ?? FakePushMessaging()),
        pushActiveProvider.overrideWith((ref) => active),
      ],
      child: const MaterialApp(home: Scaffold(body: PushSettingsTile())),
    );

Finder get _switch => find.byType(SwitchListTile);
bool _isOn(WidgetTester tester) => tester.widget<SwitchListTile>(_switch).value;

void main() {
  group('visibility', () {
    testWidgets('hidden when push is not set up in this build (so today\'s app is unchanged)', (tester) async {
      await tester.pumpWidget(_app(FakeDeviceApi(), messaging: const NoopPushMessaging()));
      await tester.pumpAndSettle();

      expect(_switch, findsNothing);
      expect(find.text('Push notifications'), findsNothing);
    });

    testWidgets('hidden when the setting cannot be loaded (offline)', (tester) async {
      final api = FakeDeviceApi()..preferencesError = ApiException('Could not reach the server.');
      await tester.pumpWidget(_app(api));
      await tester.pumpAndSettle();

      expect(_switch, findsNothing);
    });

    testWidgets('shown once the setting loads', (tester) async {
      await tester.pumpWidget(_app(FakeDeviceApi()));
      await tester.pumpAndSettle();

      expect(find.text('Push notifications'), findsOneWidget);
      expect(_isOn(tester), isTrue);
    });
  });

  group('what it says', () {
    testWidgets('on and registered on this device', (tester) async {
      await tester.pumpWidget(_app(FakeDeviceApi(), active: true));
      await tester.pumpAndSettle();

      expect(find.text('Campus alerts reach you even when the app is closed.'), findsOneWidget);
    });

    testWidgets('on but not registered here yet, and how to fix it', (tester) async {
      await tester.pumpWidget(_app(FakeDeviceApi(), active: false));
      await tester.pumpAndSettle();

      expect(find.textContaining('Not active on this device yet'), findsOneWidget);
      expect(find.textContaining('phone settings'), findsOneWidget);
    });

    testWidgets('off', (tester) async {
      final api = FakeDeviceApi()..preferences = const NotificationPreferences(pushEnabled: false, registeredDevices: 1);
      await tester.pumpWidget(_app(api, active: true));
      await tester.pumpAndSettle();

      expect(_isOn(tester), isFalse);
      expect(find.textContaining('Off.'), findsOneWidget);
    });
  });

  group('toggling', () {
    testWidgets('switching off saves it on the server', (tester) async {
      final api = FakeDeviceApi();
      await tester.pumpWidget(_app(api));
      await tester.pumpAndSettle();

      await tester.tap(_switch);
      await tester.pumpAndSettle();

      expect(_isOn(tester), isFalse);
      expect(api.preferences.pushEnabled, isFalse);
    });

    testWidgets('and back on again', (tester) async {
      final api = FakeDeviceApi()..preferences = const NotificationPreferences(pushEnabled: false, registeredDevices: 1);
      await tester.pumpWidget(_app(api));
      await tester.pumpAndSettle();

      await tester.tap(_switch);
      await tester.pumpAndSettle();

      expect(_isOn(tester), isTrue);
      expect(api.preferences.pushEnabled, isTrue);
    });

    testWidgets('the switch moves immediately, before the server answers', (tester) async {
      final api = FakeDeviceApi()..setPushGate = Completer<void>();
      await tester.pumpWidget(_app(api));
      await tester.pumpAndSettle();

      await tester.tap(_switch);
      await tester.pump();

      expect(_isOn(tester), isFalse, reason: 'optimistic');

      api.setPushGate!.complete();
      await tester.pumpAndSettle();
      expect(_isOn(tester), isFalse);
    });

    testWidgets('if the server refuses, the switch goes back and the reason is shown', (tester) async {
      final api = FakeDeviceApi()..setPushError = ApiException('Could not reach the server.');
      await tester.pumpWidget(_app(api));
      await tester.pumpAndSettle();

      await tester.tap(_switch);
      await tester.pumpAndSettle();

      expect(_isOn(tester), isTrue, reason: 'reverted');
      expect(find.text('Could not reach the server.'), findsOneWidget);
    });

    testWidgets('an unexpected error also reverts, with a generic message', (tester) async {
      final api = FakeDeviceApi()..setPushError = StateError('boom');
      await tester.pumpWidget(_app(api));
      await tester.pumpAndSettle();

      await tester.tap(_switch);
      await tester.pumpAndSettle();

      expect(_isOn(tester), isTrue);
      expect(find.text('Could not update the setting.'), findsOneWidget);
    });
  });

  group('PushSettingsController', () {
    ProviderContainer container(FakeDeviceApi api) {
      final c = ProviderContainer(overrides: [deviceApiProvider.overrideWithValue(api)]);
      addTearDown(c.dispose);
      c.listen(pushSettingsProvider, (_, _) {});
      return c;
    }

    test('setting the value it already has does nothing', () async {
      final api = FakeDeviceApi();
      final c = container(api);
      await c.read(pushSettingsProvider.future);

      await c.read(pushSettingsProvider.notifier).setEnabled(true);

      expect(api.preferences.pushEnabled, isTrue);
    });

    test('setting a value before the preference has loaded does nothing', () async {
      final api = FakeDeviceApi()..preferencesError = ApiException('offline');
      final c = container(api);
      await c.read(pushSettingsProvider.future).catchError((_) => const NotificationPreferences(pushEnabled: true, registeredDevices: 0));

      await c.read(pushSettingsProvider.notifier).setEnabled(false);

      expect(api.preferences.pushEnabled, isTrue, reason: 'no request was made');
    });

    test('the device count from the server is kept when the value changes', () async {
      final api = FakeDeviceApi()..preferences = const NotificationPreferences(pushEnabled: true, registeredDevices: 3);
      final c = container(api);
      await c.read(pushSettingsProvider.future);

      await c.read(pushSettingsProvider.notifier).setEnabled(false);

      expect(c.read(pushSettingsProvider).requireValue.registeredDevices, 3);
    });
  });
}
