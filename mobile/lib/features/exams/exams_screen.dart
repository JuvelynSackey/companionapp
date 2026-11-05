import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/campus_companion_theme.dart';
import '../../core/utils/ics_exporter.dart';
import '../../core/utils/ics_share.dart';
import '../../data/models/exam.dart';
import '../../data/models/exam_countdown.dart';
import '../../widgets/campus_card_tile.dart';
import 'add_exam_dialog.dart';
import 'exam_mode_screen.dart';
import 'exams_providers.dart';

class ExamsScreen extends ConsumerWidget {
  const ExamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exams = ref.watch(examsControllerProvider);
    final sorted = ExamCountdownUtils.getSortedUpcomingExams(exams);
    final next = ExamCountdownUtils.findNextUpcomingExam(exams);

    return Scaffold(
      body: exams.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No exams added yet. Tap + to add one.', textAlign: TextAlign.center),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_month_outlined, size: 18),
                        label: const Text('Export to Calendar'),
                        onPressed: () => shareIcsFile(IcsExporter.generateExamsIcs(exams), 'exams.ics'),
                      ),
                    ),
                    if (!kIsWeb) ...[
                      const SizedBox(width: 8),
                      Expanded(child: _ExamRemindersButton(exams: exams)),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                if (next != null) _NextExamCard(countdown: next),
                const SizedBox(height: 16),
                // The next exam is the card above; the list holds the rest, so
                // nothing is shown twice.
                if (sorted.any((c) => c.exam.id != next?.exam.id)) ...[
                  Text(next != null ? 'Later exams' : 'Exams', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                ],
                for (final countdown in sorted)
                  if (countdown.exam.id != next?.exam.id) _ExamCard(countdown: countdown),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'exams_fab',
        onPressed: () => showDialog(context: context, builder: (_) => const AddExamDialog()),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _NextExamCard extends ConsumerWidget {
  const _NextExamCard({required this.countdown});
  final ExamCountdown countdown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campus = Theme.of(context).campusTheme;
    void onDelete() => ref.read(examsControllerProvider.notifier).delete(countdown.exam.id);
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
            children: [
              const Expanded(child: Text('Next Exam', style: TextStyle(color: Colors.white70))),
              // This exam is no longer repeated in the list below, so it is
              // edited and deleted from here.
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                tooltip: 'Edit exam',
                visualDensity: VisualDensity.compact,
                onPressed: () => showDialog(context: context, builder: (_) => AddExamDialog(existing: countdown.exam)),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                tooltip: 'Delete exam',
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${countdown.exam.courseCode} · ${countdown.exam.courseTitle}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            countdown.formattedDaysRemaining,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Text(
            '${countdown.formattedExamDate} · ${countdown.exam.startTime} - ${countdown.exam.endTime}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white70),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(campus.innerRadius)),
            ),
            icon: const Icon(Icons.fullscreen),
            label: const Text('Enter Exam Mode'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ExamModeScreen(exam: countdown.exam)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamCard extends ConsumerWidget {
  const _ExamCard({required this.countdown});
  final ExamCountdown countdown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exam = countdown.exam;
    final campus = Theme.of(context).campusTheme;
    // "Urgent" per the design system's amber status treatment — an exam
    // that's today or tomorrow, not just "any upcoming exam".
    final urgent = !countdown.isPast && (countdown.isToday || countdown.isTomorrow);
    final amber = Colors.amber.shade700;

    return CampusCardTile(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: campus.cardDecoration(glow: urgent).copyWith(
            border: Border.all(color: urgent ? amber : campus.subtleBorder, width: urgent ? 1.5 : 1),
          ),
      radius: campus.cardRadius,
      // Not a ListTile: its trailing slot has a fixed height, and the
      // days-remaining label with two icon buttons overflowed it by 8 pixels.
      child: InkWell(
        onTap: () => showDialog(context: context, builder: (_) => AddExamDialog(existing: exam)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${exam.courseCode} · ${exam.courseTitle}', style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 2),
                    Text(
                      '${countdown.formattedExamDate} · ${exam.startTime}-${exam.endTime}\n${exam.venue}'
                      '${exam.seatRange.isNotEmpty ? '\n${exam.seatRange}' : ''}',
                      style: TextStyle(color: campus.textMuted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      countdown.formattedDaysRemaining,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: countdown.isPast ? campus.textMuted : (urgent ? amber : campus.accentGlow),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.fullscreen, size: 20),
                        tooltip: 'Exam Mode',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ExamModeScreen(exam: exam)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        tooltip: 'Delete exam',
                        onPressed: () => ref.read(examsControllerProvider.notifier).delete(exam.id),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExamRemindersButton extends ConsumerStatefulWidget {
  const _ExamRemindersButton({required this.exams});
  final List<Exam> exams;

  @override
  ConsumerState<_ExamRemindersButton> createState() => _ExamRemindersButtonState();
}

class _ExamRemindersButtonState extends ConsumerState<_ExamRemindersButton> {
  bool _busy = false;

  Future<void> _enableReminders() async {
    setState(() => _busy = true);
    try {
      final service = ref.read(notificationServiceProvider);
      await service.requestPermission();
      for (final exam in widget.exams) {
        await service.scheduleExamReminder(exam);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reminders set for ${widget.exams.length} exams')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not set reminders. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: _busy
          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.notifications_active_outlined, size: 18),
      label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Remind Me', maxLines: 1, softWrap: false)),
      onPressed: _busy ? null : _enableReminders,
    );
  }
}
