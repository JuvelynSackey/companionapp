import 'package:mobile/data/api/admin_api.dart';
import 'package:mobile/data/models/app_user.dart';
import 'package:mobile/features/auth/session_controller.dart';

/// Shared fakes for the admin tests.

/// Permissions as the backend derives them from the role (ROLE_PERMISSIONS in
/// authController.js), limited to the ones the app checks.
const _permissionsByRole = <String, Set<String>>{
  'admin': {'events:create', 'quizzes:create'},
  'lecturer': {'events:create', 'quizzes:create'},
  'student': <String>{},
};

AppUser userWithRole(String role, {int userId = 1}) => AppUser(
      userId: userId,
      fullName: 'Test $role',
      email: '$role@ug.edu.gh',
      role: role,
      permissions: _permissionsByRole[role] ?? const {},
    );

final adminUser = userWithRole('admin', userId: 1);
final lecturerUser = userWithRole('lecturer', userId: 7);
final studentUser = userWithRole('student', userId: 3);

/// Signed-in user without touching storage or the network.
class FakeSessionController extends SessionController {
  FakeSessionController(this._user);
  final AppUser? _user;

  @override
  Future<AppUser?> build() async => _user;
}

class FakeAdminApi implements AdminApi {
  final provisioned = <Map<String, String>>[];
  final deletedEventIds = <int>[];

  /// Awaited inside each call, so a test can hold a request in flight.
  Future<void> Function()? onProvision;
  Future<void> Function(int eventId)? onDelete;

  /// Thrown (after the call is recorded) when set.
  Object? provisionError;
  Object? deleteError;

  @override
  Future<AppUser> provisionUser({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    provisioned.add({'fullName': fullName, 'email': email, 'password': password, 'role': role});
    await onProvision?.call();
    if (provisionError != null) throw provisionError!;
    return AppUser(
      userId: 100 + provisioned.length,
      fullName: fullName,
      email: email,
      role: role,
      permissions: const {},
    );
  }

  @override
  Future<void> deleteEvent(int eventId) async {
    deletedEventIds.add(eventId);
    await onDelete?.call(eventId);
    if (deleteError != null) throw deleteError!;
  }
}
