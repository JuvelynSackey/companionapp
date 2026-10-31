import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app_root.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/storage/local_prefs.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/data/api/auth_api.dart';
import 'package:mobile/data/repositories/auth_repository.dart';
import 'package:mobile/features/auth/sign_in_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/google_auth_fakes.dart';

class _TokenStorage extends TokenStorage {
  String? _token;
  @override
  Future<String?> readToken() async => _token;
  @override
  Future<void> saveToken(String token) async => _token = token;
  @override
  Future<void> clearToken() async => _token = null;
}

class _RejectingAuthApi extends AuthApi {
  _RejectingAuthApi() : super(ApiClient(TokenStorage()));

  @override
  Future<AuthResult> login({required String email, required String password}) async =>
      throw ApiException('Invalid email or password', statusCode: 401);
}

/// Goes through AppRoot's gate, not SignInScreen alone: the gate used to swap
/// the whole screen for a spinner and then a full-page "Retry" error on a
/// failed login, so the form and its error message disappeared.
void main() {
  testWidgets('a rejected login keeps the login form and shows the message on it', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({'is_onboarding_completed': true});
    final prefs = await LocalPrefs.create();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        localPrefsProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(
          AuthRepository(_RejectingAuthApi(), _TokenStorage(), googleAuth: FakeGoogleAuthService(available: false)),
        ),
      ],
      child: const AppRoot(),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'student@ug.edu.gh');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'wrong-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget, reason: 'the form must stay on screen');
    expect(find.text('Invalid email or password'), findsOneWidget);
    expect(find.text('Retry'), findsNothing, reason: 'no full-page error for a failed login');
  });
}
