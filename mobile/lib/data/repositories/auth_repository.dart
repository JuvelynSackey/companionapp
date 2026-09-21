import '../../core/network/api_exception.dart';
import '../../core/storage/token_storage.dart';
import '../api/auth_api.dart';
import '../models/app_user.dart';

/// Distinguishes "never signed in" from "was signed in, but the token is no
/// longer valid" — both resolve to a null user, but only the latter should
/// show the student a "session expired" message instead of a plain sign-in
/// screen.
class SessionRestoreResult {
  const SessionRestoreResult({required this.user, required this.expired});
  final AppUser? user;
  final bool expired;
}

class AuthRepository {
  AuthRepository(this._api, this._tokenStorage);

  final AuthApi _api;
  final TokenStorage _tokenStorage;

  Future<AppUser> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final result = await _api.register(fullName: fullName, email: email, password: password);
    await _tokenStorage.saveToken(result.token);
    return result.user;
  }

  Future<AppUser> login({required String email, required String password}) async {
    final result = await _api.login(email: email, password: password);
    await _tokenStorage.saveToken(result.token);
    return result.user;
  }

  /// Restores a session on app launch by validating the stored token.
  /// Returns a null user if there's no token or the backend has confirmed
  /// it's no longer valid (401, `expired: true`). Any other failure — no
  /// connection, timeout, a backend error — leaves the token untouched and
  /// rethrows, since the token itself may still be perfectly valid; the
  /// caller should offer a retry rather than silently signing the student
  /// out over a network blip.
  Future<SessionRestoreResult> restoreSession() async {
    final token = await _tokenStorage.readToken();
    if (token == null) return const SessionRestoreResult(user: null, expired: false);
    try {
      final user = await _api.me();
      return SessionRestoreResult(user: user, expired: false);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _tokenStorage.clearToken();
        return const SessionRestoreResult(user: null, expired: true);
      }
      rethrow;
    }
  }

  Future<void> signOut() => _tokenStorage.clearToken();
}
