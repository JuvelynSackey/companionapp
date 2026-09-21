import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_root.dart';
import 'core/providers/core_providers.dart';
import 'core/services/push_bootstrap.dart';
import 'core/services/push_coordinator.dart';
import 'core/storage/local_prefs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localPrefs = await LocalPrefs.create();
  // Push notifications: the no-op unless built with --dart-define=FCM_ENABLED=true.
  final pushMessaging = await createPushMessaging();

  runApp(
    ProviderScope(
      overrides: [
        localPrefsProvider.overrideWithValue(localPrefs),
        pushMessagingProvider.overrideWithValue(pushMessaging),
      ],
      child: const AppRoot(),
    ),
  );
}
