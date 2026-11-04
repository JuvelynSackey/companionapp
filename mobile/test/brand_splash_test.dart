import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app_root.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/storage/local_prefs.dart';
import 'package:mobile/data/models/app_user.dart';
import 'package:mobile/features/auth/session_controller.dart';
import 'package:mobile/features/auth/sign_in_screen.dart';
import 'package:mobile/widgets/brand_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the launch restore open until the test completes it.
class _PendingSessionController extends SessionController {
  _PendingSessionController(this._restore);
  final Completer<AppUser?> _restore;

  @override
  Future<AppUser?> build() => _restore.future;
}

void main() {
  testWidgets('the branded splash shows while the session is restored, then gives way', (tester) async {
    SharedPreferences.setMockInitialValues({'is_onboarding_completed': true});
    final prefs = await LocalPrefs.create();
    final restore = Completer<AppUser?>();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        localPrefsProvider.overrideWithValue(prefs),
        sessionControllerProvider.overrideWith(() => _PendingSessionController(restore)),
      ],
      child: const AppRoot(),
    ));
    await tester.pump();

    expect(find.byType(BrandSplash), findsOneWidget);
    expect(find.text('Campus Companion'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.bySemanticsLabel('Campus Companion is loading'), findsOneWidget);

    restore.complete(null);
    await tester.pumpAndSettle();
    expect(find.byType(BrandSplash), findsNothing);
    expect(find.byType(SignInScreen), findsOneWidget);
  });
}
