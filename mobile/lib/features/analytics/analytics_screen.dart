import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/campus_companion_theme.dart';
import '../../data/logic/academic_engine.dart';
import '../../data/models/course_grade.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/campus_card_tile.dart';
import '../onboarding/institution_controller.dart';
import 'analytics_providers.dart';
import 'target_class_predictor.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grades = ref.watch(gradesProvider);
    final institution = ref.watch(institutionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(gradesProvider.future),
        child: AsyncValueView<List<CourseGrade>>(
          value: grades,
          onRetry: () => ref.invalidate(gradesProvider),
          data: (context, items) {
            final metric = AcademicEngine.calculate(items, institution);
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ScorecardCard(metric: metric, institutionShortCode: institution.shortCode, institutionBadgeColor: institution.primaryColor),
                const SizedBox(height: 16),
                const TargetClassPredictorWidget(),
                const SizedBox(height: 24),
                Text('Courses', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No grades recorded yet.'),
                  )
                else
                  ...items.map((g) => _GradeCard(grade: g)),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Metric hero card now uses the cyan design system as its primary
/// treatment (per the rollout decision); institution color is demoted to
/// a small corner badge rather than the whole card background.
class _ScorecardCard extends StatelessWidget {
  const _ScorecardCard({required this.metric, required this.institutionShortCode, required this.institutionBadgeColor});
  final AcademicMetricResult metric;
  final String institutionShortCode;
  final Color institutionBadgeColor;

  @override
  Widget build(BuildContext context) {
    final campus = Theme.of(context).campusTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(campus.cardRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          // In dark mode the theme's greens are pale, and white text on them is
          // hard to read; use the Dashboard card's deep green instead.
          colors: Theme.of(context).brightness == Brightness.dark
              ? const [CampusColors.brandDeep, CampusColors.brand]
              : [campus.accentGlow, Theme.of(context).colorScheme.primary],
        ),
        boxShadow: [BoxShadow(color: campus.accentGlow.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.4), blurRadius: 24, spreadRadius: 1)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(metric.metricLabel, style: const TextStyle(color: Colors.white70)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: institutionBadgeColor, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  institutionShortCode,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            metric.formattedScore,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(metric.classLabel, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: metric.honoursColor, borderRadius: BorderRadius.circular(20)),
            child: Text(metric.honoursClass, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(height: 8),
          Text(metric.statusSummary, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _GradeCard extends StatelessWidget {
  const _GradeCard({required this.grade});
  final CourseGrade grade;

  @override
  Widget build(BuildContext context) {
    final campus = Theme.of(context).campusTheme;
    return CampusCardTile(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: campus.cardDecoration(),
      radius: campus.cardRadius,
      child: ListTile(
        title: Text('${grade.courseCode} · ${grade.courseTitle}'),
        subtitle: Text('${grade.semester} · ${grade.creditHours} credit hours', style: TextStyle(color: campus.textMuted)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              grade.letterGrade,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: grade.passed ? campus.accentGlow : Theme.of(context).colorScheme.error,
              ),
            ),
            Text('${grade.score.toStringAsFixed(0)}%', style: TextStyle(color: campus.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
