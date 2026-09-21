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
                for (final countdown in sorted) _ExamCard(countdown: countdown),
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

class _NextExamCard extends StatelessWidget {
  const _NextExamCard({required this.countdown});
  final ExamCountdown countdown;

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
          colors: [campus.accentGlow, Theme.of(context).colorScheme.primary],
        ),
        boxShadow: [BoxShadow(color: campus.accentGlow.withValues(alpha: 0.4), blurRadius: 24, spreadRadius: 1)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Next Exam', style: TextStyle(color: Colors.white70)),
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
      child: ListTile(
        onTap: () => showDialog(context: context, builder: (_) => AddExamDialog(existing: exam)),
        title: Text('${exam.courseCode} · ${exam.courseTitle}'),
        subtitle: Text(
          '${countdown.formattedExamDate} · ${exam.startTime}-${exam.endTime}\n${exam.venue}'
          '${exam.seatRange.isNotEmpty ? '\n${exam.seatRange}' : ''}',
          style: TextStyle(color: campus.textMuted),
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              countdown.formattedDaysRemaining,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: countdown.isPast ? campus.textMuted : (urgent ? amber : campus.accentGlow),
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
                  onPressed: () => ref.read(examsControllerProvider.notifier).delete(exam.id),
                ),
              ],
            ),
          ],
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
      label: const Text('Remind Me'),
      onPressed: _busy ? null : _enableReminders,
    );
  }
}
