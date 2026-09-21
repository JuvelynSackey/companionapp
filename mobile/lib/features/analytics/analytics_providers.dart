import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../data/logic/academic_engine.dart';
import '../../data/logic/grade_prediction_engine.dart';
import '../../data/models/course_grade.dart';
import '../../data/models/institution_profile.dart';
import '../onboarding/institution_controller.dart';

final gradesProvider = FutureProvider.autoDispose<List<CourseGrade>>((ref) {
  return ref.watch(gradeApiProvider).fetch();
});

/// Re-read after every write via `ref.invalidate(localPrefsProvider)`, same
/// convention as the rest of the app's local-only state (see AlertsScreen).
final remainingCreditsProvider = Provider.autoDispose<int?>((ref) => ref.watch(localPrefsProvider).remainingCredits);

final targetHonoursTitleProvider = Provider.autoDispose<String?>((ref) => ref.watch(localPrefsProvider).targetHonoursTitle);

/// The next honours tier above the student's current standing — used as the
/// target class until they explicitly pick one from the dropdown, so the
/// predictor only needs one piece of setup (remaining credits) rather than two.
HonoursThreshold _defaultTargetClass(InstitutionProfile institution, AcademicMetricResult metric) {
  final above = institution.honoursThresholds.where((t) => t.minScore > metric.scoreValue).toList()
    ..sort((a, b) => a.minScore.compareTo(b.minScore));
  return above.isNotEmpty ? above.first : institution.honoursThresholds.first;
}

/// Shared by the Analytics predictor card and the Dashboard snapshot card so
/// the prediction math lives in exactly one place. Null means the feature
/// isn't usable yet — no grades, or the student hasn't set remaining
/// credits — callers render nothing rather than a fabricated prediction.
final academicPlanProvider = FutureProvider.autoDispose<GradePredictionResult?>((ref) async {
  final grades = await ref.watch(gradesProvider.future);
  if (grades.isEmpty) return null;

  final remainingCredits = ref.watch(remainingCreditsProvider);
  if (remainingCredits == null) return null;

  final institution = ref.watch(institutionControllerProvider);
  final metric = AcademicEngine.calculate(grades, institution);

  final targetTitle = ref.watch(targetHonoursTitleProvider);
  final targetClass = targetTitle == null
      ? _defaultTargetClass(institution, metric)
      : institution.honoursThresholds.firstWhere(
          (t) => t.title == targetTitle,
          orElse: () => _defaultTargetClass(institution, metric),
        );

  return GradePredictionEngine.predict(
    currentScore: metric.scoreValue,
    completedCredits: metric.totalCredits,
    remainingCredits: remainingCredits,
    targetClass: targetClass,
    institution: institution,
  );
});
