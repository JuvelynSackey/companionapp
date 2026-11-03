import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app_root.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/storage/local_prefs.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/data/api/announcement_api.dart';
import 'package:mobile/data/api/auth_api.dart';
import 'package:mobile/data/api/location_api.dart';
import 'package:mobile/data/models/announcement.dart';
import 'package:mobile/data/models/campus_event.dart';
import 'package:mobile/data/models/campus_location.dart';
import 'package:mobile/data/repositories/auth_repository.dart';
import 'package:mobile/features/auth/session_controller.dart';
import 'package:mobile/features/auth/sign_in_screen.dart';
import 'package:mobile/features/shell/app_shell.dart';
import 'package:mobile/features/shell/guest_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/club_fakes.dart';
import 'support/google_auth_fakes.dart';

class _NoTokenStorage extends TokenStorage {
  @override
  Future<String?> readToken() async => null;
  @override
  Future<void> saveToken(String token) async {}
  @override
  Future<void> clearToken() async {}
}

class _AnnouncementApi implements AnnouncementApi {
  @override
  Future<List<Announcement>> fetch({int limit = 50}) async => [
        Announcement(
          announcementId: 1,
          title: 'Library opens late this week',
          message: 'Open until midnight.',
          category: 'general',
          postedBy: 'Admin',
          datePosted: DateTime.utc(2026, 10, 30),
        ),
      ];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('guests only read announcements');
}

class _LocationApi implements LocationApi {
  @override
  Future<List<CampusLocation>> fetch({String? category, String? search}) async => const [];
  @override
  Future<List<String>> fetchCategories() async => const [];
}

/// FakeEventApi.register / cancelRegistration throw, so an RSVP request that
/// slipped past the guest check would fail the test.
final _event = CampusEvent(
  eventId: 1,
  title: 'Freshers Fair',
  description: '',
  eventDate: DateTime.utc(2030, 5, 1, 14),
  location: 'Great Hall',
  clubName: null,
  attendeeCount: 7,
  isRegistered: false,
);

Future<(Widget, FakeClubApi)> _app() async {
  SharedPreferences.setMockInitialValues({'is_onboarding_completed': true});
  final prefs = await LocalPrefs.create();
  final clubs = FakeClubApi([cs, photo]);
  final app = ProviderScope(
    overrides: [
      localPrefsProvider.overrideWithValue(prefs),
      authRepositoryProvider.overrideWithValue(
        AuthRepository(AuthApi(ApiClient(_NoTokenStorage())), _NoTokenStorage(),
            googleAuth: FakeGoogleAuthService(available: false)),
      ),
      announcementApiProvider.overrideWithValue(_AnnouncementApi()),
      eventApiProvider.overrideWithValue(FakeEventApi([_event])),
      clubApiProvider.overrideWithValue(clubs),
      locationApiProvider.overrideWithValue(_LocationApi()),
    ],
    child: const AppRoot(),
  );
  return (app, clubs);
}

Future<FakeClubApi> _enterGuestMode(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final (app, clubs) = await _app();
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
  expect(find.byType(SignInScreen), findsOneWidget);

  await tester.tap(find.text('Continue as Guest'));
  await tester.pumpAndSettle();
  return clubs;
}

Finder _navTab(String label) => find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

bool _guestMode(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(AppRoot))).read(guestModeProvider);

void main() {
  testWidgets('Continue as Guest opens the guest shell with the campus feeds, not the personal app', (tester) async {
    await _enterGuestMode(tester);

    expect(find.byType(GuestShell), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    expect(find.text("You're browsing as a guest"), findsOneWidget);
    expect(find.text('Library opens late this week'), findsOneWidget, reason: 'announcements load without a token');
    for (final tab in ['Alerts', 'Events', 'Clubs', 'Map']) {
      expect(_navTab(tab), findsOneWidget);
    }
    expect(_navTab('Timetable'), findsNothing);
    expect(_navTab('Exams'), findsNothing);
  });

  testWidgets('a guest who taps RSVP is asked to sign in and no request is sent', (tester) async {
    await _enterGuestMode(tester);
    await tester.tap(_navTab('Events'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'RSVP'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in to continue'), findsOneWidget);
    expect(find.textContaining('RSVP for events'), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.byType(GuestShell), findsOneWidget, reason: '"Not now" keeps them browsing');

    await tester.tap(find.widgetWithText(OutlinedButton, 'RSVP'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(_guestMode(tester), isFalse);
  });

  testWidgets('a guest who taps Join is asked to sign in, and "My clubs" is not offered', (tester) async {
    final clubs = await _enterGuestMode(tester);
    await tester.tap(_navTab('Clubs'));
    await tester.pumpAndSettle();

    expect(find.text('Computer Science Society'), findsOneWidget);
    expect(find.text('My clubs'), findsNothing);

    await tester.tap(find.text('Join').first);
    await tester.pumpAndSettle();
    expect(find.text('Sign in to continue'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(clubs.joined, isEmpty);
    expect(find.text('Join'), findsNWidgets(2), reason: 'no optimistic flip to Leave');
  });

  testWidgets('a guest on a pushed screen who chooses Sign in lands on the sign-in screen', (tester) async {
    await _enterGuestMode(tester);
    await tester.tap(_navTab('Clubs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Computer Science Society'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Join'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.text('Computer Science Society'), findsNothing, reason: 'the club page was popped');
  });

  testWidgets('the banner Sign in button leaves guest mode', (tester) async {
    await _enterGuestMode(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.byType(GuestShell), findsNothing);
    expect(_guestMode(tester), isFalse);
  });
}
