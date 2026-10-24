import 'dart:async';

import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/services/google_auth_service.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/data/api/auth_api.dart';
import 'package:mobile/data/models/app_user.dart';

/// Shared fakes for the Google sign-in tests. Nothing here needs Firebase or
/// a device with Google Play services.

/// A sign-in flow the test drives by hand: [idToken] is what `signIn()`
/// resolves to (null simulates the person cancelling the native picker).
class FakeGoogleAuthService implements GoogleAuthService {
  FakeGoogleAuthService({this.available = true, this.idToken = 'firebase-id-token-1'});

  bool available;

  /// Set to null to simulate a cancelled picker. Set [signInError] to
  /// simulate signIn() throwing instead (e.g. Firebase misconfigured).
  String? idToken;
  Object? signInError;
  int signInCalls = 0;
  int signOutCalls = 0;

  /// Awaited inside signIn(), so a test can hold a sign-in in flight to
  /// inspect loading state before letting it resolve.
  Completer<void>? gate;

  @override
  bool get isAvailable => available;

  @override
  Future<String?> signIn() async {
    signInCalls++;
    await gate?.future;
    if (signInError != null) throw signInError!;
    return idToken;
  }

  @override
  Future<void> signOut() async => signOutCalls++;
}

/// Records every googleSignIn() call and answers with [result] (an
/// AppUser/token pair) or throws [error] if set.
class FakeGoogleAuthApi extends AuthApi {
  // The real ApiClient is never used — every method this fake needs is
  // overridden below.
  FakeGoogleAuthApi({this.result}) : super(ApiClient(TokenStorage()));

  AuthResult? result;
  Object? error;
  final idTokensSent = <String>[];

  @override
  Future<AuthResult> googleSignIn(String firebaseIdToken) async {
    idTokensSent.add(firebaseIdToken);
    if (error != null) throw error!;
    return result ??
        AuthResult('jwt-from-google', AppUser(userId: 1, fullName: 'Ama', email: 'ama@ug.edu.gh', role: 'student', permissions: const {}));
  }
}
