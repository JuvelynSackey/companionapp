import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../data/models/institution_profile.dart';
import '../../data/models/local_student_profile.dart';

/// The selected institution — branding/theme only in Phase 1 (backend is
/// single-tenant), mirrors InstitutionPreferencesRepository.kt.
class InstitutionController extends Notifier<InstitutionProfile> {
  @override
  InstitutionProfile build() {
    final id = ref.watch(localPrefsProvider).selectedInstitutionId;
    return id != null ? InstitutionRegistry.getById(id) : InstitutionRegistry.ug;
  }

  Future<void> select(InstitutionProfile institution) async {
    await ref.read(localPrefsProvider).setSelectedInstitutionId(institution.id);
    state = institution;
  }
}

final institutionControllerProvider = NotifierProvider<InstitutionController, InstitutionProfile>(
  InstitutionController.new,
);

class OnboardingController extends Notifier<bool> {
  @override
  bool build() => ref.watch(localPrefsProvider).isOnboardingCompleted;

  Future<void> complete() async {
    await ref.read(localPrefsProvider).setOnboardingCompleted(true);
    state = true;
  }
}

final onboardingControllerProvider = NotifierProvider<OnboardingController, bool>(
  OnboardingController.new,
);

/// Local-only cosmetic profile detail (role, student id, level, programme)
/// — see LocalStudentProfile for why this never touches the backend.
class LocalProfileController extends Notifier<LocalStudentProfile> {
  @override
  LocalStudentProfile build() => ref.watch(localPrefsProvider).localStudentProfile;

  Future<void> save(LocalStudentProfile profile) async {
    await ref.read(localPrefsProvider).saveLocalStudentProfile(profile);
    state = profile;
  }
}

final localProfileControllerProvider = NotifierProvider<LocalProfileController, LocalStudentProfile>(
  LocalProfileController.new,
);
