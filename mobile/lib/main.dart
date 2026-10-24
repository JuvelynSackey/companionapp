import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_root.dart';
import 'core/providers/core_providers.dart';
import 'core/services/google_auth_bootstrap.dart';
import 'core/services/push_bootstrap.dart';
import 'core/services/push_coordinator.dart';
import 'core/storage/local_prefs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localPrefs = await LocalPrefs.create();
  // Both the no-op unless built with --dart-define=FCM_ENABLED=true /
  // --dart-define=GOOGLE_SIGN_IN_ENABLED=true — they share one Firebase app
  // (see firebase_bootstrap.dart), so either can be on independently.
  final pushMessaging = await createPushMessaging();
  final googleAuthService = await createGoogleAuthService();

  runApp(
    ProviderScope(
      overrides: [
        localPrefsProvider.overrideWithValue(localPrefs),
        pushMessagingProvider.overrideWithValue(pushMessaging),
        googleAuthServiceProvider.overrideWithValue(googleAuthService),
      ],
      child: const AppRoot(),
    ),
  );
}
