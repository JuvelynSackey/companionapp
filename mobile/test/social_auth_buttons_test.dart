import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/storage/local_prefs.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/data/repositories/auth_repository.dart';
import 'package:mobile/features/auth/widgets/social_auth_buttons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/google_auth_fakes.dart';

/// In-memory fake — never touches the real FlutterSecureStorage platform channel.
class _InMemoryTokenStorageForTest extends TokenStorage {
  String? _token;
  @override
  Future<String?> readToken() async => _token;
  @override
  Future<void> saveToken(String token) async => _token = token;
  @override
  Future<void> clearToken() async => _token = null;
}

Future<Widget> _app({required FakeGoogleAuthService google, required FakeGoogleAuthApi api}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await LocalPrefs.create();
  return ProviderScope(
    overrides: [
      localPrefsProvider.overrideWithValue(prefs),
      googleAuthServiceProvider.overrideWithValue(google),
      authRepositoryProvider.overrideWithValue(
        AuthRepository(api, _InMemoryTokenStorageForTest(), googleAuth: google),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: SocialAuthButtons())),
  );
}

Finder get _googleButton => find.widgetWithText(OutlinedButton, 'Continue with Google');

void main() {
  testWidgets('not configured: the Google button keeps its normal label and stays tappable', (tester) async {
    await tester.pumpWidget(await _app(google: FakeGoogleAuthService(available: false), api: FakeGoogleAuthApi()));
    await tester.pumpAndSettle();

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.textContaining('Coming soon'), findsNothing);
    final button = tester.widget<OutlinedButton>(_googleButton);
    expect(button.onPressed, isNotNull, reason: 'tappable so it can show the coming-soon notice');
  });

  testWidgets('tapping it while not configured shows a Coming soon message', (tester) async {
    await tester.pumpWidget(await _app(google: FakeGoogleAuthService(available: false), api: FakeGoogleAuthApi()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue with Google'));
    await tester.pump();

    expect(find.text('Google sign-in is coming soon.'), findsOneWidget);
  });

  testWidgets('configured: tapping signs in, no error shown', (tester) async {
    final google = FakeGoogleAuthService();
    final api = FakeGoogleAuthApi();
    await tester.pumpWidget(await _app(google: google, api: api));
    await tester.pumpAndSettle();

    await tester.tap(_googleButton);
    await tester.pumpAndSettle();

    expect(google.signInCalls, 1);
    expect(api.idTokensSent, ['firebase-id-token-1']);
    expect(find.textContaining('failed'), findsNothing);
  });

  testWidgets('a cancelled picker shows no error', (tester) async {
    final google = FakeGoogleAuthService(idToken: null);
    final api = FakeGoogleAuthApi();
    await tester.pumpWidget(await _app(google: google, api: api));
    await tester.pumpAndSettle();

    await tester.tap(_googleButton);
    await tester.pumpAndSettle();

    expect(google.signInCalls, 1);
    expect(api.idTokensSent, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a backend rejection shows its message', (tester) async {
    final google = FakeGoogleAuthService();
    final api = FakeGoogleAuthApi()..error = ApiException('Invalid or expired Google sign-in token', statusCode: 401);
    await tester.pumpWidget(await _app(google: google, api: api));
    await tester.pumpAndSettle();

    await tester.tap(_googleButton);
    await tester.pumpAndSettle();

    expect(find.text('Invalid or expired Google sign-in token'), findsOneWidget);
  });

  testWidgets('while signing in, the button shows a spinner', (tester) async {
    final google = FakeGoogleAuthService()..gate = Completer<void>();
    final api = FakeGoogleAuthApi();
    await tester.pumpWidget(await _app(google: google, api: api));
    await tester.pumpAndSettle();

    // tap() completes once its own gesture settles; it does not wait for the
    // onPressed handler's Future, which is parked on the gate.
    await tester.tap(_googleButton);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    google.gate!.complete();
    await tester.pumpAndSettle();
    expect(google.signInCalls, 1);
  });
}
