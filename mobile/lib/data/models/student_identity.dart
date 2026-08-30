import 'institution_profile.dart';
import 'local_student_profile.dart';

/// Shared by the Digital ID card and the Event Pass — the local profile's
/// own studentId if the student entered one during onboarding, otherwise a
/// deterministic fallback derived from their backend userId.
String displayStudentId(int userId, InstitutionProfile institution, LocalStudentProfile localProfile) {
  if (localProfile.studentId.isNotEmpty) return localProfile.studentId;
  return '${institution.shortCode}-${userId.toString().padLeft(6, '0')}';
}
