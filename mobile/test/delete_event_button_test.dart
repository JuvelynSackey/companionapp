import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/storage/local_prefs.dart';
import 'package:mobile/data/models/app_user.dart';
import 'package:mobile/data/models/campus_event.dart';
import 'package:mobile/features/admin/delete_event_button.dart';
import 'package:mobile/features/auth/session_controller.dart';
import 'package:mobile/features/events/event_pass_controller.dart';
import 'package:mobile/features/events/events_providers.dart';
import 'package:mobile/features/events/events_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/admin_fakes.dart';
import 'support/club_fakes.dart';

CampusEvent _event(int id, String title) => CampusEvent(
      eventId: id,
      title: title,
      description: 'About $title',
      eventDate: DateTime.utc(2030, 5, 1, 14),
      location: 'Great Hall',
      clubName: null,
      attendeeCount: 3,
      isRegistered: false,
    );

class _Env {
  _Env({required this.container, required this.admin, required this.events});
  final ProviderContainer container;
  final FakeAdminApi admin;
  final FakeEventApi events;
}

Future<_Env> _env(AppUser? user, {List<CampusEvent>? events}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await LocalPrefs.create();
  final admin = FakeAdminApi();
  final eventApi = FakeEventApi(events ?? [_event(5, 'Hackathon'), _event(6, 'Debate Night')]);
  final container = ProviderContainer(overrides: [
    localPrefsProvider.overrideWithValue(prefs),
    adminApiProvider.overrideWithValue(admin),
    eventApiProvider.overrideWithValue(eventApi),
    sessionControllerProvider.overrideWith(() => FakeSessionController(user)),
  ]);
  addTearDown(container.dispose);
  await container.read(sessionControllerProvider.future);
  return _Env(container: container, admin: admin, events: eventApi);
}

/// The button on its own, plus a listener that keeps eventsProvider alive so
/// a refresh after deleting is observable as another fetch.
Widget _buttonApp(_Env env, {ValueNotifier<bool>? show}) => UncontrolledProviderScope(
      container: env.container,
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              ref.watch(eventsProvider);
              return ValueListenableBuilder<bool>(
                valueListenable: show ?? ValueNotifier(true),
                builder: (context, visible, _) =>
                    visible ? const DeleteEventButton(eventId: 5, eventTitle: 'Hackathon') : const SizedBox(),
              );
            },
          ),
        ),
      ),
    );

Widget _screenApp(_Env env) => UncontrolledProviderScope(
      container: env.container,
      child: const MaterialApp(home: EventsScreen()),
    );

void main() {
  group('who sees it', () {
    for (final user in [studentUser, lecturerUser, null]) {
      testWidgets('${user?.role ?? 'signed-out user'} gets no delete button', (tester) async {
        final env = await _env(user);
        await tester.pumpWidget(_buttonApp(env));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.delete_outline), findsNothing);
      });
    }

    testWidgets('an admin does', (tester) async {
      final env = await _env(adminUser);
      await tester.pumpWidget(_buttonApp(env));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(find.byTooltip('Delete event'), findsOneWidget);
    });
  });

  group('deleting', () {
    testWidgets('asks first, and cancelling deletes nothing', (tester) async {
      final env = await _env(adminUser);
      await tester.pumpWidget(_buttonApp(env));
      await tester.pumpAndSettle();
      final fetchesBefore = env.events.fetchCount;

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.text('Delete event?'), findsOneWidget);
      expect(find.textContaining('"Hackathon" will be removed for everyone'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(env.admin.deletedEventIds, isEmpty);
      expect(env.events.fetchCount, fetchesBefore);
    });

    testWidgets('confirming deletes the event, refreshes the list and confirms', (tester) async {
      final env = await _env(adminUser);
      await tester.pumpWidget(_buttonApp(env));
      await tester.pumpAndSettle();
      final fetchesBefore = env.events.fetchCount;

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(env.admin.deletedEventIds, [5]);
      expect(env.events.fetchCount, fetchesBefore + 1, reason: 'events list refreshed');
      expect(find.text('Deleted "Hackathon".'), findsOneWidget);
    });

    testWidgets('drops the RSVP pass this device holds for the event', (tester) async {
      final env = await _env(adminUser);
      final passes = env.container.read(eventPassControllerProvider.notifier);
      await passes.generate(event: _event(5, 'Hackathon'), studentName: 'A', studentId: '1');
      await passes.generate(event: _event(6, 'Debate Night'), studentName: 'A', studentId: '1');
      await tester.pumpWidget(_buttonApp(env));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      final remaining = env.container.read(eventPassControllerProvider);
      expect(remaining.containsKey(5), isFalse);
      expect(remaining.containsKey(6), isTrue, reason: 'other events untouched');
    });

    testWidgets('a backend refusal is shown and the list is not refreshed', (tester) async {
      final env = await _env(adminUser);
      env.admin.deleteError = ApiException('You can only delete events you created', statusCode: 403);
      await tester.pumpWidget(_buttonApp(env));
      await tester.pumpAndSettle();
      final fetchesBefore = env.events.fetchCount;

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('You can only delete events you created'), findsOneWidget);
      expect(find.textContaining('Deleted'), findsNothing);
      expect(env.events.fetchCount, fetchesBefore);
    });

    testWidgets('a 404 (already deleted elsewhere) is shown and the stale list is refreshed', (tester) async {
      final env = await _env(adminUser);
      env.admin.deleteError = ApiException('Event not found', statusCode: 404);
      await tester.pumpWidget(_buttonApp(env));
      await tester.pumpAndSettle();
      final fetchesBefore = env.events.fetchCount;

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Event not found'), findsOneWidget);
      expect(env.events.fetchCount, fetchesBefore + 1);
    });

    testWidgets('finishes cleanly even if the card is removed while the request is in flight', (tester) async {
      final env = await _env(adminUser);
      final gate = Completer<void>();
      env.admin.onDelete = (_) => gate.future;
      final show = ValueNotifier(true);
      await tester.pumpWidget(_buttonApp(env, show: show));
      await tester.pumpAndSettle();
      final fetchesBefore = env.events.fetchCount;

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pump();

      show.value = false; // e.g. a pull-to-refresh rebuilt the list without this card
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.delete_outline), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(env.events.fetchCount, fetchesBefore + 1);
    });
  });

  group('on the Events screen', () {
    testWidgets('an admin gets a delete button on every event card', (tester) async {
      final env = await _env(adminUser);
      await tester.pumpWidget(_screenApp(env));
      await tester.pumpAndSettle();

      expect(find.text('Hackathon'), findsOneWidget);
      expect(find.text('Debate Night'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
    });

    testWidgets('a student sees the events but no delete buttons', (tester) async {
      final env = await _env(studentUser);
      await tester.pumpWidget(_screenApp(env));
      await tester.pumpAndSettle();

      expect(find.text('Hackathon'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('deleting from a card removes that event from the list', (tester) async {
      final env = await _env(adminUser);
      env.admin.onDelete = (id) async => env.events.events = env.events.events.where((e) => e.eventId != id).toList();
      await tester.pumpWidget(_screenApp(env));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(of: find.widgetWithText(Card, 'Hackathon'), matching: find.byIcon(Icons.delete_outline)));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(env.admin.deletedEventIds, [5]);
      expect(find.text('Hackathon'), findsNothing);
      expect(find.text('Debate Night'), findsOneWidget);
    });
  });
}
