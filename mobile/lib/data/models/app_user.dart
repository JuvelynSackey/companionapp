class AppUser {
  AppUser({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.permissions,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        userId: json['userId'] as int,
        fullName: json['fullName'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        permissions: (json['permissions'] as List? ?? const []).map((e) => e as String).toSet(),
      );

  final int userId;
  final String fullName;
  final String email;
  final String role;

  /// Granular permission strings the backend derives from role (see
  /// ROLE_PERMISSIONS in authController.js) — computed fresh on every
  /// login/register/me response rather than cached client-side, so a role
  /// change takes effect on the next sign-in without reissuing tokens.
  final Set<String> permissions;

  bool get isAdmin => role == 'admin';

  /// Event creation is open to lecturers/club coordinators too, not just
  /// admins — see requireRole('lecturer', 'admin') on POST /api/events.
  bool get canCreateEvents => permissions.contains('events:create');

  /// Quiz authoring (manual or past-paper-derived) is open to lecturers too.
  bool get canCreateQuizzes => permissions.contains('quizzes:create');
}
