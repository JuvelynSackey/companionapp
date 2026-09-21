import '../../core/network/api_client.dart';
import '../models/notification_preferences.dart';

class DeviceApi {
  DeviceApi(this._client);
  final ApiClient _client;

  /// Idempotent: safe to call on every sign-in and whenever the token changes.
  /// If another account had registered this token it moves to the caller.
  Future<void> registerToken(String token, {required String platform}) => _client.guard(() async {
        await _client.dio.post('/users/me/device-token', data: {'token': token, 'platform': platform});
      });

  /// Also succeeds if the token was already gone, so sign-out never fails on it.
  Future<void> unregisterToken(String token) => _client.guard(() async {
        await _client.dio.delete('/users/me/device-token', data: {'token': token});
      });

  Future<NotificationPreferences> fetchPreferences() => _client.guard(() async {
        final res = await _client.dio.get('/users/me/notification-preferences');
        return NotificationPreferences.fromJson(res.data as Map<String, dynamic>);
      });

  Future<NotificationPreferences> setPushEnabled(bool enabled) => _client.guard(() async {
        final res = await _client.dio.put('/users/me/notification-preferences', data: {'pushEnabled': enabled});
        return NotificationPreferences.fromJson(res.data as Map<String, dynamic>);
      });
}
