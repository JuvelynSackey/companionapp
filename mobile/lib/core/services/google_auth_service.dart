/// What the app needs from Google Sign-In, without naming Firebase or
/// google_sign_in. The real implementation is FirebaseGoogleAuthService; when
/// it is not configured the app uses [NoopGoogleAuthService], and tests use a
/// fake. Nothing else in the app imports firebase_auth or google_sign_in, so
/// they stay optional — mirrors push_messaging.dart's pattern exactly.
abstract class GoogleAuthService {
  /// False when Google sign-in is not set up (no Firebase project / the
  /// provider not enabled / feature off). The UI shows the button disabled,
  /// labelled "Coming soon", when this is false.
  bool get isAvailable;

  /// Opens the native Google account picker and signs into Firebase with
  /// whichever account is chosen. Returns a Firebase ID token ready to send
  /// to `POST /api/auth/google`, or null if the person cancelled the picker
  /// — deliberately not an error (a cancel is the common case, not
  /// exceptional), so the caller just returns to what it was doing. Any
  /// other failure (network, misconfiguration) throws.
  Future<String?> signIn();

  /// Signs this device out of the native Google session, so the next "sign
  /// in with Google" shows the account picker again rather than silently
  /// reusing whichever account was last chosen.
  Future<void> signOut();
}

/// The default: Google sign-in is not configured. Nothing is requested or
/// shown; [signIn] always resolves to null, matching "the person got no
/// account" rather than throwing for a button the UI has already disabled.
class NoopGoogleAuthService implements GoogleAuthService {
  const NoopGoogleAuthService();

  @override
  bool get isAvailable => false;

  @override
  Future<String?> signIn() async => null;

  @override
  Future<void> signOut() async {}
}
