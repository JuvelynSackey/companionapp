import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/logic/grade_prediction_engine.dart';
import 'package:mobile/data/models/institution_profile.dart';

HonoursThreshold _thresholdOf(InstitutionProfile institution, String title) =>
    institution.honoursThresholds.firstWhere((t) => t.title == title);

void main() {
  group('UG (gpa4_0 scale, max 4.00)', () {
    final ug = InstitutionRegistry.ug;
    final firstClass = _thresholdOf(ug, 'First Class Honours'); // minScore 3.60
    final secondUpper = _thresholdOf(ug, 'Second Class (Upper)'); // minScore 3.00
    final pass = _thresholdOf(ug, 'Pass'); // minScore 1.00

    test('a required average comfortably below the top 5% of the scale is achievable', () {
      // (3.00*120 - 2.50*60) / 60 = (360 - 150) / 60 = 3.50
      final result = GradePredictionEngine.predict(
        currentScore: 2.50,
        completedCredits: 60,
        remainingCredits: 60,
        targetClass: secondUpper,
        institution: ug,
      );
      expect(result.requiredAverage, closeTo(3.50, 0.001));
      expect(result.feasibility, PredictionFeasibility.achievable);
      expect(result.isPercentage, isFalse);
    });

    test('a required average in the top 5% of the scale (>= 3.80 on a 4.00 max) is a stretch goal', () {
      // (3.60*120 - 3.40*60) / 60 = (432 - 204) / 60 = 3.80
      final result = GradePredictionEngine.predict(
        currentScore: 3.40,
        completedCredits: 60,
        remainingCredits: 60,
        targetClass: firstClass,
        institution: ug,
      );
      expect(result.requiredAverage, closeTo(3.80, 0.001));
      expect(result.feasibility, PredictionFeasibility.stretch);
    });

    test('required average above the 4.00 max scale is statistically unattainable', () {
      // (3.60*120 - 1.50*90) / 30 = (432 - 135) / 30 = 9.9
      final result = GradePredictionEngine.predict(
        currentScore: 1.50,
        completedCredits: 90,
        remainingCredits: 30,
        targetClass: firstClass,
        institution: ug,
      );
      expect(result.requiredAverage, greaterThan(4.0));
      expect(result.feasibility, PredictionFeasibility.unattainable);
    });

    test('a current average already well above the target reports alreadyAchieved', () {
      // (1.00*120 - 3.90*100) / 20 = (120 - 390) / 20 = -13.5
      final result = GradePredictionEngine.predict(
        currentScore: 3.90,
        completedCredits: 100,
        remainingCredits: 20,
        targetClass: pass,
        institution: ug,
      );
      expect(result.requiredAverage, lessThanOrEqualTo(0));
      expect(result.feasibility, PredictionFeasibility.alreadyAchieved);
    });

    test('zero remaining credits reflects final standing instead of dividing by zero', () {
      final result = GradePredictionEngine.predict(
        currentScore: 3.20,
        completedCredits: 120,
        remainingCredits: 0,
        targetClass: firstClass,
        institution: ug,
      );
      expect(result.requiredAverage, 3.20);
      expect(result.feasibility, PredictionFeasibility.unattainable);
    });
  });

  test('KNUST (CWA, max 100): the stretch band scales proportionally, not to 3.80/4.00', () {
    final knust = InstitutionRegistry.knust;
    final firstClass = _thresholdOf(knust, 'First Class Honours'); // minScore 70.0
    final result = GradePredictionEngine.predict(
      currentScore: 55,
      completedCredits: 60,
      remainingCredits: 60,
      targetClass: firstClass,
      institution: knust,
    );
    // (70*120 - 55*60) / 60 = (8400 - 3300) / 60 = 85.0 -> below 95% of 100, so achievable, not stretch
    expect(result.requiredAverage, closeTo(85.0, 0.001));
    expect(result.feasibility, PredictionFeasibility.achievable);
    expect(result.isPercentage, isTrue);
    expect(result.formattedRequiredAverage, contains('CWA'));
  });

  test('ATU (5.0 scale): maxScale-relative bands use 5.0, not 4.0', () {
    final atu = InstitutionRegistry.atu;
    final firstClass = _thresholdOf(atu, 'First Class Honours'); // minScore 4.50
    final result = GradePredictionEngine.predict(
      currentScore: 3.00,
      completedCredits: 30,
      remainingCredits: 30,
      targetClass: firstClass,
      institution: atu,
    );
    // (4.50*60 - 3.00*30) / 30 = (270 - 90) / 30 = 6.0 -> exceeds 5.0 max
    expect(result.requiredAverage, greaterThan(5.0));
    expect(result.feasibility, PredictionFeasibility.unattainable);
  });
}
