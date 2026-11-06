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
import 'what_if_screen.dart';
import 'add_result_dialog.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/core_providers.dart';

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
                if (!metric.isPercentage) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WhatIfScreen())),
                    icon: const Icon(Icons.calculate_outlined),
                    label: const Text('What if? Try expected grades'),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Text('Results by semester', style: Theme.of(context).textTheme.titleMedium)),
                    TextButton.icon(
                      onPressed: () async {
                        final saved = await showDialog<bool>(context: context, builder: (_) => const AddResultDialog());
                        if (saved != true) return;
                        ref.invalidate(gradesProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Result added. Your CGPA and FGPA now include it.')));
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add a result'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No grades recorded yet.'),
                  )
                else
                  for (final semester in AcademicEngine.semesterBreakdown(items, institution)) ...[
                    _SemesterHeader(summary: semester, isPercentage: metric.isPercentage),
                    ...semester.courses.map((g) => _GradeCard(grade: g)),
                    const SizedBox(height: 8),
                  ],
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

/// A semester's heading, like a transcript row: its GPA, the running CGPA,
/// and the credits taken that semester and in total.
class _SemesterHeader extends StatelessWidget {
  const _SemesterHeader({required this.summary, required this.isPercentage});
  final SemesterSummary summary;
  final bool isPercentage;

  @override
  Widget build(BuildContext context) {
    final campus = Theme.of(context).campusTheme;
    final unit = isPercentage ? 'CWA' : 'GPA';
    final cumulative = isPercentage ? 'CWA' : 'CGPA';
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(summary.semester, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(
            '$unit ${summary.gpa.toStringAsFixed(2)} · $cumulative ${summary.cgpa.toStringAsFixed(2)} · '
            '${summary.credits} credits (${summary.cumulativeCredits} in total)',
            style: TextStyle(color: campus.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _GradeCard extends ConsumerWidget {
  const _GradeCard({required this.grade});
  final CourseGrade grade;

  /// Only the student's own, self-entered results can be removed.
  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove this result?'),
        content: Text('${grade.courseCode} · ${grade.courseTitle} (${grade.letterGrade}), entered by you.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(gradeApiProvider).deleteMine(grade.gradeId);
      ref.invalidate(gradesProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Result removed.')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campus = Theme.of(context).campusTheme;
    return CampusCardTile(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: campus.cardDecoration(),
      radius: campus.cardRadius,
      child: ListTile(
        title: Text('${grade.courseCode} · ${grade.courseTitle}'),
        subtitle: Text(
          grade.selfReported ? '${grade.creditHours} credit hours · Entered by you (tap to remove)' : '${grade.creditHours} credit hours',
          style: TextStyle(color: campus.textMuted),
        ),
        onTap: grade.selfReported ? () => _remove(context, ref) : null,
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
            // A self-entered result has a letter, not a real mark.
            if (!grade.selfReported) Text('${grade.score.toStringAsFixed(0)}%', style: TextStyle(color: campus.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
