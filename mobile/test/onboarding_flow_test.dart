import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app_root.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/storage/local_prefs.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/data/api/auth_api.dart';
import 'package:mobile/data/repositories/auth_repository.dart';
import 'package:mobile/features/auth/sign_in_screen.dart';
import 'package:mobile/features/onboarding/institution_picker_screen.dart';
import 'package:mobile/features/onboarding/profile_setup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/google_auth_fakes.dart';

class _TokenStorage extends TokenStorage {
  @override
  Future<String?> readToken() async => null;
  @override
  Future<void> saveToken(String token) async {}
  @override
  Future<void> clearToken() async {}
}

Future<void> _pumpFreshInstall(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final prefs = await LocalPrefs.create();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      localPrefsProvider.overrideWithValue(prefs),
      authRepositoryProvider.overrideWithValue(
        AuthRepository(AuthApi(ApiClient(TokenStorage())), _TokenStorage(), googleAuth: FakeGoogleAuthService(available: false)),
      ),
    ],
    child: const AppRoot(),
  ));
  await tester.pumpAndSettle();
}

Future<void> _throughToProfileStep(WidgetTester tester) async {
  await tester.tap(find.text('Get Started'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('University of Ghana'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
  expect(find.byType(ProfileSetupScreen), findsOneWidget);
}

/// Walks the real flow from AppRoot. Welcome pushes the institution picker,
/// which pushes the profile step, so finishing has to clear both pushed
/// screens, not just the top one, or the student lands back on the picker.
void main() {
  testWidgets('finishing the profile step lands on Login, not back on the institution picker', (tester) async {
    await _pumpFreshInstall(tester);
    await _throughToProfileStep(tester);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.byType(InstitutionPickerScreen), findsNothing);
    expect(find.byType(ProfileSetupScreen), findsNothing);
    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('skipping the profile step also lands on Login', (tester) async {
    await _pumpFreshInstall(tester);
    await _throughToProfileStep(tester);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.byType(InstitutionPickerScreen), findsNothing);
    expect(find.byType(SignInScreen), findsOneWidget);
  });
}
