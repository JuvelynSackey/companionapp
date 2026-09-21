import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/campus_companion_theme.dart';
import '../../data/logic/grade_prediction_engine.dart';
import '../../widgets/campus_card_tile.dart';
import '../onboarding/institution_controller.dart';
import 'analytics_providers.dart';
import 'set_remaining_credits_dialog.dart';

Color _feasibilityColor(PredictionFeasibility feasibility) => switch (feasibility) {
      PredictionFeasibility.alreadyAchieved => const Color(0xFF10B981),
      PredictionFeasibility.achievable => const Color(0xFF10B981),
      PredictionFeasibility.stretch => const Color(0xFFF59E0B),
      PredictionFeasibility.unattainable => const Color(0xFFEF4444),
    };

String _feasibilityLabel(PredictionFeasibility feasibility) => switch (feasibility) {
      PredictionFeasibility.alreadyAchieved => 'Already Achieved',
      PredictionFeasibility.achievable => 'Achievable',
      PredictionFeasibility.stretch => 'Stretch Goal',
      PredictionFeasibility.unattainable => 'Statistically Unattainable',
    };

/// Interactive "what average do I need?" card. Reads/writes the same local
/// prefs + academicPlanProvider the Dashboard's AcademicSnapshotCard uses, so
/// changing the target class here updates the Dashboard too.
class TargetClassPredictorWidget extends ConsumerWidget {
  const TargetClassPredictorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campus = Theme.of(context).campusTheme;
    final remainingCredits = ref.watch(remainingCreditsProvider);

    if (remainingCredits == null) {
      return CampusCardTile(
        decoration: campus.cardDecoration(),
        radius: campus.cardRadius,
        child: ListTile(
          leading: Icon(Icons.flag_outlined, color: campus.accentGlow),
          title: const Text('Set up Grade Prediction'),
          subtitle: Text(
            'Tell us how many credit hours you have left to see what average you need for a target class.',
            style: TextStyle(color: campus.textMuted),
          ),
          trailing: FilledButton(
            style: campus.primaryButtonStyle,
            onPressed: () => showDialog(context: context, builder: (_) => const SetRemainingCreditsDialog()),
            child: const Text('Set Up'),
          ),
        ),
      );
    }

    final institution = ref.watch(institutionControllerProvider);
    final planAsync = ref.watch(academicPlanProvider);

    return planAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (plan) {
        if (plan == null) return const SizedBox.shrink();
        final color = _feasibilityColor(plan.feasibility);
        final targetableThresholds = institution.honoursThresholds.where((t) => t.minScore > 0).toList();

        return CampusCardTile(
          decoration: campus.cardDecoration(),
          radius: campus.cardRadius,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Target Class Predictor', style: Theme.of(context).textTheme.titleMedium),
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: campus.textMuted, size: 20),
                    tooltip: 'Edit remaining credit hours',
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => SetRemainingCreditsDialog(initialValue: remainingCredits),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: plan.targetClass.title,
                decoration: campus.inputDecoration(label: 'Target class'),
                items: [
                  for (final threshold in targetableThresholds)
                    DropdownMenuItem(value: threshold.title, child: Text(threshold.title)),
                ],
                onChanged: (title) async {
                  if (title == null) return;
                  await ref.read(localPrefsProvider).setTargetHonoursTitle(title);
                  ref.invalidate(localPrefsProvider);
                },
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    plan.formattedRequiredAverage,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('required average', style: TextStyle(color: campus.textMuted, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  _feasibilityLabel(plan.feasibility),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(height: 8),
              Text(plan.summary, style: TextStyle(color: campus.textMuted)),
            ],
          ),
        );
      },
    );
  }
}
