import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'firebase_push_messaging.dart';
import 'push_messaging.dart';

/// Push is opt-in at build time:
///
///   flutter run --dart-define=FCM_ENABLED=true
///
/// Without it (the default, and what the deployed web build uses) Firebase is
/// never initialised and the app behaves exactly as it did before push existed.
const bool _pushEnabled = bool.fromEnvironment('FCM_ENABLED');

/// Called once from main(). Never throws: if Firebase cannot start (no
/// google-services.json yet, wrong config, unsupported platform) the app
/// carries on with push off rather than failing to launch.
///
/// [options] is for platforms that need explicit config; on Android
/// google-services.json supplies it. `flutterfire configure` generates a
/// firebase_options.dart to pass here (see docs/push-notifications.md).
Future<PushMessaging> createPushMessaging({FirebaseOptions? options}) async {
  if (!_pushEnabled) return const NoopPushMessaging();

  try {
    await Firebase.initializeApp(options: options);
    return FirebasePushMessaging();
  } catch (error) {
    debugPrint('Push notifications disabled: Firebase could not start ($error).');
    return const NoopPushMessaging();
  }
}
