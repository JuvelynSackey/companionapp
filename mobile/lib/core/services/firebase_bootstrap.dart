import 'package:firebase_core/firebase_core.dart';

/// Ensures Firebase's default app is initialised exactly once, shared by
/// push_bootstrap.dart and google_auth_bootstrap.dart — so turning on just
/// one of FCM_ENABLED / GOOGLE_SIGN_IN_ENABLED never depends on the other
/// also being on, and turning on both never tries to initialise Firebase
/// twice (which throws a duplicate-app error). Rethrows on failure; each
/// caller decides its own fallback (both fall back to a no-op service).
Future<void> ensureFirebaseInitialized({FirebaseOptions? options}) async {
  if (Firebase.apps.isNotEmpty) return;
  await Firebase.initializeApp(options: options);
}
