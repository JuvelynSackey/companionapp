import '../../core/network/api_client.dart';
import '../models/app_user.dart';

class AuthResult {
  AuthResult(this.token, this.user);
  final String token;
  final AppUser user;
}

class AuthApi {
  AuthApi(this._client);
  final ApiClient _client;

  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
  }) =>
      _client.guard(() async {
        final res = await _client.dio.post('/auth/register', data: {
          'fullName': fullName,
          'email': email,
          'password': password,
        });
        return AuthResult(res.data['token'] as String, AppUser.fromJson(res.data['user']));
      });

  Future<AuthResult> login({required String email, required String password}) =>
      _client.guard(() async {
        final res = await _client.dio.post('/auth/login', data: {
          'email': email,
          'password': password,
        });
        return AuthResult(res.data['token'] as String, AppUser.fromJson(res.data['user']));
      });

  Future<AppUser> me() => _client.guard(() async {
        final res = await _client.dio.get('/auth/me');
        return AppUser.fromJson(res.data['user']);
      });
}
