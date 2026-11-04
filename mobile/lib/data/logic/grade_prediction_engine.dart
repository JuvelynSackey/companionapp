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
    this.basedOnFgpa = false,
  });

  final HonoursThreshold targetClass;
  final double requiredAverage;
  final double maxScale;
  final bool isPercentage;
  final PredictionFeasibility feasibility;
  final String summary;

  /// True when the target was met on the level-weighted FGPA rather than the
  /// plain cumulative average.
  final bool basedOnFgpa;

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
///
/// When [levelTotals] are given (an institution that classifies on a
/// level-weighted FGPA, such as UG's 1:1:2:2), the target is met on that
/// FGPA instead. Which levels the remaining credits will fall in is not
/// known, so the programme's total credits are assumed to be spread evenly
/// over the weighted levels, and the remaining credits fill each level up to
/// its share in order (see [remainingByLevel]). The FGPA is then linear in
/// the required average r, which is solved exactly.
class GradePredictionEngine {
  GradePredictionEngine._();

  static GradePredictionResult predict({
    required double currentScore,
    required int completedCredits,
    required int remainingCredits,
    required HonoursThreshold targetClass,
    required InstitutionProfile institution,
    Map<int, ({int credits, double points})>? levelTotals,
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
    final required = levelTotals == null
        ? ((targetClass.minScore * totalCredits) - (currentScore * completedCredits)) / remainingCredits
        : _requiredForWeightedTarget(targetClass.minScore, levelTotals, remainingCredits, institution.levelWeights);

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
      basedOnFgpa: levelTotals != null,
    );
  }

  /// Spreads [remaining] credits over the weighted levels: each level's share
  /// of the whole programme is (completed + remaining) / number of levels,
  /// and levels are topped up to that share in order. Any credits left over
  /// (a level already past its share) go to the highest level.
  static Map<int, int> remainingByLevel(Map<int, ({int credits, double points})> done, int remaining, Map<int, int> weights) {
    final levels = weights.keys.toList()..sort();
    final completed = done.values.fold<int>(0, (sum, t) => sum + t.credits);
    final share = (completed + remaining) / levels.length;
    final plan = <int, int>{};
    var left = remaining;
    for (final level in levels) {
      final room = (share - (done[level]?.credits ?? 0)).floor().clamp(0, left);
      if (room > 0) plan[level] = room;
      left -= room;
    }
    if (left > 0) plan[levels.last] = (plan[levels.last] ?? 0) + left;
    return plan;
  }

  /// The average r over the remaining credits that brings the weighted level
  /// average to [target]: FGPA(r) = sum over levels of w * (P + r * R) / (C + R),
  /// divided by the sum of w, is linear in r.
  static double _requiredForWeightedTarget(
    double target,
    Map<int, ({int credits, double points})> done,
    int remaining,
    Map<int, int> weights,
  ) {
    final plan = remainingByLevel(done, remaining, weights);
    var constant = 0.0, slope = 0.0, weightSum = 0;
    for (final level in weights.keys) {
      final c = done[level]?.credits ?? 0;
      final r = plan[level] ?? 0;
      if (c + r == 0) continue;
      final w = weights[level]!;
      constant += w * (done[level]?.points ?? 0) / (c + r);
      slope += w * r / (c + r);
      weightSum += w;
    }
    return (target * weightSum - constant) / slope;
  }
}
