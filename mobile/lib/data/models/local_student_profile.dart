enum StudentRole { student, lecturer }

/// Local-only, cosmetic profile detail — never sent to the backend (which
/// only has student/admin roles and only stores fullName/email/password).
/// Purely for personalizing the onboarding flow and the Digital ID card.
class LocalStudentProfile {
  const LocalStudentProfile({
    required this.role,
    required this.studentId,
    required this.academicLevel,
    required this.programme,
  });

  factory LocalStudentProfile.fromJson(Map<String, dynamic> json) => LocalStudentProfile(
        role: StudentRole.values.firstWhere((r) => r.name == json['role'], orElse: () => StudentRole.student),
        studentId: json['studentId'] as String? ?? '',
        academicLevel: json['academicLevel'] as String? ?? '',
        programme: json['programme'] as String? ?? '',
      );

  static const empty = LocalStudentProfile(role: StudentRole.student, studentId: '', academicLevel: '', programme: '');

  final StudentRole role;
  final String studentId;
  final String academicLevel;
  final String programme;

  bool get isComplete => studentId.isNotEmpty || academicLevel.isNotEmpty || programme.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'role': role.name,
        'studentId': studentId,
        'academicLevel': academicLevel,
        'programme': programme,
      };
}
