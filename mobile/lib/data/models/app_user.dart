class AppUser {
  AppUser({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        userId: json['userId'] as int,
        fullName: json['fullName'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
      );

  final int userId;
  final String fullName;
  final String email;
  final String role;

  bool get isAdmin => role == 'admin';
}
