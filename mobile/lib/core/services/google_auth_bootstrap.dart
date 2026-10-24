import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_bootstrap.dart';
import 'firebase_google_auth_service.dart';
import 'google_auth_service.dart';

/// Google sign-in is opt-in at build time, same as push:
///
///   flutter run --dart-define=GOOGLE_SIGN_IN_ENABLED=true \
///               --dart-define=GOOGLE_SERVER_CLIENT_ID=`the Web client ID`
///
/// Without it (the default) Google sign-in is never touched and the button
/// stays disabled. GOOGLE_SERVER_CLIENT_ID is the "Web client (auto created
/// by Google Service)" OAuth client id from google-services.json — needed on
/// Android to get back a usable ID token, not a secret (it identifies the
/// app to Google, like a package name does). See docs/google-sign-in.md.
const bool _googleSignInEnabled = bool.fromEnvironment('GOOGLE_SIGN_IN_ENABLED');
const String _googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

/// Called once from main(), after (or alongside) createPushMessaging() —
/// both share one Firebase app via ensureFirebaseInitialized(), so either or
/// both can be enabled independently. Never throws: if Firebase or Google
/// Sign-In cannot start (not configured yet, wrong id, unsupported platform)
/// the app carries on with the button disabled rather than failing to launch.
Future<GoogleAuthService> createGoogleAuthService({FirebaseOptions? options}) async {
  if (!_googleSignInEnabled) return const NoopGoogleAuthService();

  try {
    await ensureFirebaseInitialized(options: options);
    await GoogleSignIn.instance.initialize(
      serverClientId: _googleServerClientId.isEmpty ? null : _googleServerClientId,
    );
    return FirebaseGoogleAuthService();
  } catch (error) {
    debugPrint('Google sign-in disabled: could not start ($error).');
    return const NoopGoogleAuthService();
  }
}
