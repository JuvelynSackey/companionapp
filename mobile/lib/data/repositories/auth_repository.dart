import '../../core/storage/token_storage.dart';
import '../api/auth_api.dart';
import '../models/app_user.dart';

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
  /// Returns null if there's no token or it's no longer valid.
  Future<AppUser?> restoreSession() async {
    final token = await _tokenStorage.readToken();
    if (token == null) return null;
    try {
      return await _api.me();
    } catch (_) {
      await _tokenStorage.clearToken();
      return null;
    }
  }

  Future<void> signOut() => _tokenStorage.clearToken();
}
