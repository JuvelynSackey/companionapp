import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'google_auth_service.dart';

/// GoogleAuthService over google_sign_in (the native account picker) and
/// firebase_auth (exchanging the Google credential for a Firebase ID token,
/// which is what the backend actually verifies — see
/// backend/src/services/googleIdTokenVerifier.js).
///
/// Only ever constructed by google_auth_bootstrap.dart, after
/// GoogleSignIn.instance.initialize() succeeded. This is the one file that
/// touches google_sign_in/firebase_auth directly; it is not unit-tested (it
/// needs a real Firebase project and a device with Google Play services),
/// the same exemption firebase_push_messaging.dart has — kept as thin as
/// possible so there is as little untested surface as that implies.
class FirebaseGoogleAuthService implements GoogleAuthService {
  FirebaseGoogleAuthService();

  @override
  bool get isAvailable => true;

  @override
  Future<String?> signIn() async {
    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      // canceled/interrupted/uiUnavailable all mean "no account was chosen",
      // which is not an error for this app — the person just closed the
      // picker. Anything else (e.g. configuration errors) is real and rethrown.
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted ||
          e.code == GoogleSignInExceptionCode.uiUnavailable) {
        return null;
      }
      rethrow;
    }

    final googleIdToken = account.authentication.idToken;
    if (googleIdToken == null) {
      throw StateError('Google did not return an ID token for this account.');
    }

    final credential = GoogleAuthProvider.credential(idToken: googleIdToken);
    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    final firebaseIdToken = await userCredential.user?.getIdToken();
    if (firebaseIdToken == null) {
      throw StateError('Firebase did not return an ID token after signing in with Google.');
    }
    return firebaseIdToken;
  }

  @override
  Future<void> signOut() async {
    // Both independently: signing out of Firebase does not sign out of the
    // native Google session, and vice versa — without both, the next "sign
    // in with Google" could silently reuse the previous account with no
    // picker shown.
    await Future.wait([
      GoogleSignIn.instance.signOut(),
      FirebaseAuth.instance.signOut(),
    ]);
  }
}
