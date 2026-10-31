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
import '../auth/session_controller.dart';
import '../onboarding/institution_controller.dart';
import '../shell/nav_providers.dart';
import 'dashboard_providers.dart';
import 'widgets/quick_access_grid.dart';

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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const _HeroHeader(),
            const SizedBox(height: 16),
            _StatsRow(stats: data.stats),
            const _ContextActions(),
            const _AcademicSnapshotCard(),
            const _SectionTitle('Explore'),
            const QuickAccessGrid(),
            const _SectionTitle("Today's classes"),
            if (data.todaysClasses.isEmpty)
              const _EmptyHint(icon: Icons.free_breakfast_outlined, text: 'No classes scheduled for today.')
            else
              ...data.todaysClasses.map((c) => _TodayClassCard(item: c)),
            const _SectionTitle('Announcements'),
            if (data.announcements.isEmpty)
              const _EmptyHint(icon: Icons.campaign_outlined, text: 'No announcements yet.')
            else
              ...data.announcements.map((a) => _AnnouncementPreviewCard(item: a)),
            const _SectionTitle('Upcoming events'),
            if (data.upcomingEvents.isEmpty)
              const _EmptyHint(icon: Icons.event_busy_outlined, text: 'No upcoming events.')
            else
              ...data.upcomingEvents.map((e) => _EventPreviewCard(item: e)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 10),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}

/// Greeting, date and institution, with the ContextEngine's daily brief
/// folded in. The brief comes from local data (schedule, exams, locations),
/// independent of the backend dashboard fetch, so if it fails the header
/// still renders, just without the brief line.
class _HeroHeader extends ConsumerWidget {
  const _HeroHeader();

  String _greeting(int hour) => hour < 12 ? 'Good morning' : (hour < 17 ? 'Good afternoon' : 'Good evening');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final firstName = ref.watch(sessionControllerProvider).valueOrNull?.fullName.trim().split(RegExp(r'\s+')).first;
    final institution = ref.watch(institutionControllerProvider);
    final brief = ref
        .watch(dashboardContextProvider)
        .valueOrNull
        ?.where((a) => a.type == ContextActionType.dailyBrief)
        .firstOrNull
        ?.description;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CampusColors.brandDeep, CampusColors.brand],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -18,
            child: Icon(Icons.school, size: 150, color: Colors.white.withValues(alpha: 0.07)),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, d MMMM').format(now).toUpperCase(),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11.5, letterSpacing: 1.1, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  firstName == null || firstName.isEmpty ? _greeting(now.hour) : '${_greeting(now.hour)}, $firstName',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                ),
                const SizedBox(height: 4),
                Text(institution.name, style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
                if (brief != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(brief, style: const TextStyle(color: Colors.white))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The ContextEngine's actionable cards (conflicts, a class starting soon,
/// an exam approaching). Fails silently into nothing, like the brief.
class _ContextActions extends ConsumerWidget {
  const _ContextActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final others = ref
            .watch(dashboardContextProvider)
            .valueOrNull
            ?.where((a) => a.type != ContextActionType.dailyBrief)
            .toList() ??
        const [];
    return Column(
      children: [
        for (final action in others) ...[
          const SizedBox(height: 12),
          _ContextActionCard(action: action),
        ],
      ],
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
        Expanded(
          child: _StatCard(label: 'Classes today', value: '${stats.classesToday}', icon: Icons.menu_book_outlined, color: CampusColors.brand),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(label: 'Notices', value: '${stats.announcements}', icon: Icons.campaign_outlined, color: const Color(0xFFEF6C00)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(label: 'Events', value: '${stats.upcomingEvents}', icon: Icons.event_outlined, color: const Color(0xFF1E88E5)),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
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
  const _EmptyHint({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.onSurfaceVariant, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: Theme.of(context).campusTheme.textMuted))),
        ],
      ),
    );
  }
}
