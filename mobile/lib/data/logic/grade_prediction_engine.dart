import '../models/institution_profile.dart';
import 'academic_engine.dart';

enum PredictionFeasibility { alreadyAchieved, achievable, stretch, unattainable }

class GradePredictionResult {
  const GradePredictionResult({
    required this.targetClass,
    required this.requiredAverage,
    required this.maxScale,
    required this.isPercentage,
    required this.feasibility,
    required this.summary,
  });

  final HonoursThreshold targetClass;
  final double requiredAverage;
  final double maxScale;
  final bool isPercentage;
  final PredictionFeasibility feasibility;
  final String summary;

  String get formattedRequiredAverage {
    final clamped = requiredAverage.clamp(0, maxScale);
    return isPercentage ? '${clamped.toStringAsFixed(2)}% CWA' : '${clamped.toStringAsFixed(2)} / ${maxScale.toStringAsFixed(2)}';
  }
}

/// Solves for the average score a student needs across their remaining
/// credit hours to reach a target honours class by graduation:
///
///   required = (targetScore * totalCredits - currentScore * completedCredits) / remainingCredits
///
/// Generalized across every institution's grading scale rather than a fixed
/// 4.0-GPA formula, since a "stretch goal" only means something relative to
/// the scale in use (KNUST's CWA runs 0-100, ATU runs on a 5.0 scale) — the
/// stretch band is the top 5% of whatever maxScale that institution uses.
class GradePredictionEngine {
  GradePredictionEngine._();

  static GradePredictionResult predict({
    required double currentScore,
    required int completedCredits,
    required int remainingCredits,
    required HonoursThreshold targetClass,
    required InstitutionProfile institution,
  }) {
    final maxScale = AcademicEngine.maxScaleFor(institution.gradingSystem);
    final isPercentage = institution.gradingSystem == GradingSystemType.knustCwa;

    if (completedCredits <= 0 || remainingCredits <= 0) {
      final achieved = currentScore >= targetClass.minScore;
      return GradePredictionResult(
        targetClass: targetClass,
        requiredAverage: currentScore,
        maxScale: maxScale,
        isPercentage: isPercentage,
        feasibility: achieved ? PredictionFeasibility.alreadyAchieved : PredictionFeasibility.unattainable,
        summary: remainingCredits <= 0
            ? 'No remaining credits to average against — this reflects your final standing.'
            : 'Add completed courses to compute a prediction.',
      );
    }

    final totalCredits = completedCredits + remainingCredits;
    final required = ((targetClass.minScore * totalCredits) - (currentScore * completedCredits)) / remainingCredits;

    final PredictionFeasibility feasibility;
    if (required <= 0) {
      feasibility = PredictionFeasibility.alreadyAchieved;
    } else if (required > maxScale) {
      feasibility = PredictionFeasibility.unattainable;
    } else if (required >= maxScale * 0.95) {
      feasibility = PredictionFeasibility.stretch;
    } else {
      feasibility = PredictionFeasibility.achievable;
    }

    final requiredLabel = isPercentage ? '${required.toStringAsFixed(2)}% CWA' : '${required.toStringAsFixed(2)} GPA';
    final summary = switch (feasibility) {
      PredictionFeasibility.alreadyAchieved => 'Your current standing already clears ${targetClass.title} — keep it up.',
      PredictionFeasibility.achievable =>
        'Average $requiredLabel across your remaining $remainingCredits credit hours to reach ${targetClass.title}.',
      PredictionFeasibility.stretch =>
        'Reaching ${targetClass.title} needs near-perfect results across your remaining $remainingCredits credit hours.',
      PredictionFeasibility.unattainable =>
        '${targetClass.title} is no longer mathematically reachable with $remainingCredits credit hours left.',
    };

    return GradePredictionResult(
      targetClass: targetClass,
      requiredAverage: required,
      maxScale: maxScale,
      isPercentage: isPercentage,
      feasibility: feasibility,
      summary: summary,
    );
  }
}
