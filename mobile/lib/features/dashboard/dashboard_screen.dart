import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/engine/context_engine.dart';
import '../../core/theme/campus_companion_theme.dart';
import '../../data/logic/grade_prediction_engine.dart';
import '../../data/models/dashboard_data.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/campus_card_tile.dart';
import '../analytics/analytics_providers.dart';
import '../analytics/analytics_screen.dart';
import '../shell/nav_providers.dart';
import 'dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardViewProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(dashboardViewProvider.future),
      child: AsyncValueView<DashboardData>(
        value: dashboard,
        onRetry: () => ref.invalidate(dashboardViewProvider),
        data: (context, data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _ContextSection(),
            const SizedBox(height: 24),
            _StatsRow(stats: data.stats),
            const SizedBox(height: 24),
            const _AcademicSnapshotCard(),
            const SizedBox(height: 24),
            Text("Today's Classes", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (data.todaysClasses.isEmpty)
              const _EmptyHint(text: 'No classes scheduled for today.')
            else
              ...data.todaysClasses.map((c) => _TodayClassCard(item: c)),
            const SizedBox(height: 24),
            Text('Announcements', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (data.announcements.isEmpty)
              const _EmptyHint(text: 'No announcements yet.')
            else
              ...data.announcements.map((a) => _AnnouncementPreviewCard(item: a)),
            const SizedBox(height: 24),
            Text('Upcoming Events', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (data.upcomingEvents.isEmpty)
              const _EmptyHint(text: 'No upcoming events.')
            else
              ...data.upcomingEvents.map((e) => _EventPreviewCard(item: e)),
          ],
        ),
      ),
    );
  }
}

/// Daily Brief + smart action cards, powered by ContextEngine. Rendered
/// separately from the main AsyncValueView above since its data source
/// (local schedule + local exams + locations) is independent of the
/// backend dashboard fetch — a failure here shouldn't block the rest of
/// the Dashboard, so it fails silently into nothing rather than an error card.
class _ContextSection extends ConsumerWidget {
  const _ContextSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.watch(dashboardContextProvider);
    return actions.when(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        final brief = list.firstWhere((a) => a.type == ContextActionType.dailyBrief);
        final others = list.where((a) => a.type != ContextActionType.dailyBrief).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DailyBriefCard(action: brief),
            for (final action in others) ...[
              const SizedBox(height: 8),
              _ContextActionCard(action: action),
            ],
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _DailyBriefCard extends StatelessWidget {
  const _DailyBriefCard({required this.action});
  final CampusContextAction action;

  @override
  Widget build(BuildContext context) {
    final campus = Theme.of(context).campusTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(campus.cardRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [campus.accentGlow, colorScheme.primary],
        ),
        boxShadow: [BoxShadow(color: campus.accentGlow.withValues(alpha: 0.4), blurRadius: 24, spreadRadius: 1)],
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily Brief', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(action.description, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextActionCard extends ConsumerWidget {
  const _ContextActionCard({required this.action});
  final CampusContextAction action;

  (IconData, Color) _styleFor(ContextActionType type, ColorScheme scheme, CampusCompanionTheme campus) => switch (type) {
        ContextActionType.scheduleConflict => (Icons.warning_amber_rounded, scheme.error),
        ContextActionType.classStartingSoon => (Icons.directions_walk, campus.accentGlow),
        ContextActionType.examApproaching => (Icons.school_outlined, Colors.deepOrange),
        ContextActionType.dailyBrief => (Icons.wb_sunny_outlined, campus.accentGlow),
      };

  AppTab _tabFor(ContextActionType type) => switch (type) {
        ContextActionType.scheduleConflict || ContextActionType.classStartingSoon => AppTab.timetable,
        ContextActionType.examApproaching => AppTab.exams,
        ContextActionType.dailyBrief => AppTab.timetable,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final campus = Theme.of(context).campusTheme;
    final (icon, color) = _styleFor(action.type, scheme, campus);
    // High-priority: an imminent departure warning or a same-day conflict —
    // these get the signature cyan/urgent glow per the design system's
    // "Smart Travel Warnings" treatment.
    final urgent = action.requiresImmediateDeparture || action.type == ContextActionType.scheduleConflict;

    return CampusCardTile(
      decoration: campus.cardDecoration(glow: urgent).copyWith(
            border: Border.all(color: urgent ? scheme.error : campus.subtleBorder, width: urgent ? 1.5 : 1),
          ),
      radius: campus.cardRadius,
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color)),
        title: Text(action.title, style: TextStyle(fontWeight: urgent ? FontWeight.bold : FontWeight.normal)),
        subtitle: Text(action.description, style: TextStyle(color: campus.textMuted)),
        trailing: TextButton(
          onPressed: () => ref.read(selectedTabProvider.notifier).state = _tabFor(action.type),
          child: Text(action.primaryButtonText, style: TextStyle(color: campus.accentGlow)),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Classes Today', value: '${stats.classesToday}', icon: Icons.class_outlined)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Announcements', value: '${stats.announcements}', icon: Icons.campaign_outlined)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Events', value: '${stats.upcomingEvents}', icon: Icons.event_outlined)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final campus = Theme.of(context).campusTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(campus.innerRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.onPrimaryContainer),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: colorScheme.onPrimaryContainer)),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onPrimaryContainer)),
        ],
      ),
    );
  }
}

/// Compact CGPA + target-class-feasibility summary for the Daily Brief,
/// fed by the same academicPlanProvider the Analytics predictor writes to —
/// changing the target class there updates this card too. Renders nothing
/// (not a placeholder) until the student has grades and has set their
/// remaining credit hours, same "fail silently into nothing" rule as
/// _ContextSection, since this is optional enrichment, not core data.
class _AcademicSnapshotCard extends ConsumerWidget {
  const _AcademicSnapshotCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(academicPlanProvider);
    return planAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (plan) {
        if (plan == null) return const SizedBox.shrink();
        final campus = Theme.of(context).campusTheme;
        final color = switch (plan.feasibility) {
          PredictionFeasibility.alreadyAchieved || PredictionFeasibility.achievable => const Color(0xFF10B981),
          PredictionFeasibility.stretch => const Color(0xFFF59E0B),
          PredictionFeasibility.unattainable => const Color(0xFFEF4444),
        };

        return CampusCardTile(
          decoration: campus.cardDecoration(),
          radius: campus.cardRadius,
          child: ListTile(
            leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(Icons.trending_up, color: color)),
            title: Text('${plan.formattedRequiredAverage} needed for ${plan.targetClass.title}'),
            subtitle: Text(plan.summary, style: TextStyle(color: campus.textMuted)),
            trailing: TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
              child: Text('View', style: TextStyle(color: campus.accentGlow)),
            ),
          ),
        );
      },
    );
  }
}

class _TodayClassCard extends StatelessWidget {
  const _TodayClassCard({required this.item});
  final TodayClass item;

  @override
  Widget build(BuildContext context) {
    final campus = Theme.of(context).campusTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return CampusCardTile(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: campus.cardDecoration(glow: item.inProgress),
      radius: campus.cardRadius,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.inProgress ? campus.accentGlow : colorScheme.surfaceContainerHighest,
          child: Icon(Icons.menu_book, color: item.inProgress ? Colors.white : null),
        ),
        title: Text(item.courseTitle),
        subtitle: Text('${item.lecturer} · ${item.room ?? 'TBA'}', style: TextStyle(color: campus.textMuted)),
        trailing: Text('${item.startTime}\n${item.endTime}', textAlign: TextAlign.right, style: TextStyle(color: campus.textMuted, fontSize: 12)),
      ),
    );
  }
}

class _AnnouncementPreviewCard extends StatelessWidget {
  const _AnnouncementPreviewCard({required this.item});
  final DashboardAnnouncementSummary item;

  @override
  Widget build(BuildContext context) {
    final campus = Theme.of(context).campusTheme;
    return CampusCardTile(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: campus.cardDecoration(),
      radius: campus.cardRadius,
      child: ListTile(
        leading: Icon(Icons.campaign_outlined, color: campus.accentGlow),
        title: Text(item.title),
        subtitle: Text(item.message, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: campus.textMuted)),
      ),
    );
  }
}

class _EventPreviewCard extends StatelessWidget {
  const _EventPreviewCard({required this.item});
  final UpcomingEventSummary item;

  @override
  Widget build(BuildContext context) {
    final campus = Theme.of(context).campusTheme;
    return CampusCardTile(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: campus.cardDecoration(),
      radius: campus.cardRadius,
      child: ListTile(
        leading: Icon(Icons.event_outlined, color: campus.accentGlow),
        title: Text(item.title),
        subtitle: Text(
          '${DateFormat('EEE, MMM d · h:mm a').format(item.eventDate.toLocal())}${item.location != null ? ' · ${item.location}' : ''}',
          style: TextStyle(color: campus.textMuted),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: TextStyle(color: Theme.of(context).campusTheme.textMuted)),
    );
  }
}
