import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/storage/local_prefs.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/data/repositories/auth_repository.dart';
import 'package:mobile/features/auth/welcome_screen.dart';
import 'package:mobile/features/onboarding/institution_picker_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/google_auth_fakes.dart';

/// In-memory fake — never touches the real FlutterSecureStorage platform
/// channel, which just hangs (not throws) in a plain widget test with no
/// handler registered — without this, SessionController.build() never
/// resolves, SocialAuthButtons' spinner spins forever, and every
/// pumpAndSettle() in this file times out.
class _TokenStorage extends TokenStorage {
  @override
  Future<String?> readToken() async => null;
  @override
  Future<void> saveToken(String token) async {}
  @override
  Future<void> clearToken() async {}
}

Future<Widget> _app({FakeGoogleAuthService? google}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await LocalPrefs.create();
  final fakeGoogle = google ?? FakeGoogleAuthService(available: false);
  return ProviderScope(
    overrides: [
      localPrefsProvider.overrideWithValue(prefs),
      googleAuthServiceProvider.overrideWithValue(fakeGoogle),
      authRepositoryProvider.overrideWithValue(
        AuthRepository(FakeGoogleAuthApi(), _TokenStorage(), googleAuth: fakeGoogle),
      ),
    ],
    child: const MaterialApp(home: WelcomeScreen()),
  );
}

/// The default 800x600 test surface is shorter than this screen's content,
/// which puts the lower buttons/links below the visible area and out of
/// tap() 's reach — see admin_dashboard_screen_test.dart for the same pattern.
void _tallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('shows the Campus Companion headline and Get Started', (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    expect(find.text('Campus Companion'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Continue with Google (Coming soon)'), findsOneWidget, reason: 'no GoogleAuthService override: not available');
  });

  testWidgets('Get Started proceeds to the institution picker', (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.byType(InstitutionPickerScreen), findsOneWidget);
  });

  testWidgets('"Already have an account? Log in" also proceeds to the institution picker', (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Already have an account', findRichText: true));
    await tester.pumpAndSettle();

    expect(find.byType(InstitutionPickerScreen), findsOneWidget);
  });

  testWidgets('when Google sign-in is configured, the button is enabled and says so', (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(await _app(google: FakeGoogleAuthService()));
    await tester.pumpAndSettle();

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Google (Coming soon)'), findsNothing);
  });

  testWidgets('Apple and Guest are always shown disabled, labelled Coming soon', (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(await _app(google: FakeGoogleAuthService()));
    await tester.pumpAndSettle();

    expect(find.text('Continue with Apple (Coming soon)'), findsOneWidget);
    expect(find.text('Continue as Guest (Coming soon)'), findsOneWidget);
  });

  testWidgets('tapping Apple or Guest shows a Coming soon message, not nothing', (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue with Apple (Coming soon)'));
    await tester.pump();
    expect(find.text('Apple sign-in is coming soon.'), findsOneWidget);

    await tester.tap(find.text('Continue as Guest (Coming soon)'));
    await tester.pump();
    expect(find.text('Guest mode is coming soon.'), findsOneWidget);
  });
}
