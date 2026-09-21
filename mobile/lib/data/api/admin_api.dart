import '../../core/network/api_client.dart';
import '../models/app_user.dart';

/// Admin-only endpoints. The backend enforces the role (requireAdmin /
/// requireRole); hiding the UI from other roles is a convenience, not the gate.
class AdminApi {
  AdminApi(this._client);
  final ApiClient _client;

  /// Creates a lecturer or admin account directly — there is no self-service
  /// path to either role. [role] must be 'lecturer' or 'admin'.
  Future<AppUser> provisionUser({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) =>
      _client.guard(() async {
        final res = await _client.dio.post('/admin/provision-user', data: {
          'fullName': fullName,
          'email': email,
          'password': password,
          'role': role,
        });
        return AppUser.fromJson(res.data['user']);
      });

  /// Deletes any event (RSVPs go with it). Lecturers can delete only their
  /// own events on the backend; this app offers deletion to admins only.
  Future<void> deleteEvent(int eventId) => _client.guard(() async {
        await _client.dio.delete('/events/$eventId');
      });
}
