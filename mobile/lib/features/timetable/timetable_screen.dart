import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/campus_companion_theme.dart';
import '../../core/utils/ics_exporter.dart';
import '../../core/utils/ics_share.dart';
import '../../data/models/schedule_entry.dart';
import '../../widgets/campus_card_tile.dart';
import 'add_schedule_dialog.dart';
import 'import_schedule_button.dart';
import 'timetable_providers.dart';

const _dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

/// Every student manages their own timetable now (see the migration plan's
/// local-first Timetable decision) — no admin gating, no backend calls.
class TimetableScreen extends ConsumerWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(filteredScheduleProvider);
    final selectedDay = ref.watch(selectedDayFilterProvider);

    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: selectedDay == null,
                    onSelected: (_) => ref.read(selectedDayFilterProvider.notifier).state = null,
                  ),
                ),
                for (var i = 1; i <= 7; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(_dayNames[i - 1].substring(0, 3)),
                      selected: selectedDay == i,
                      onSelected: (_) => ref.read(selectedDayFilterProvider.notifier).state = i,
                    ),
                  ),
              ],
            ),
          ),
          if (entries.isEmpty)
            const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No classes yet. Add one manually or import a timetable you exported earlier.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_month_outlined, size: 18),
                      label: const Text('Export'),
                      onPressed: () => shareIcsFile(IcsExporter.generateScheduleIcs(entries), 'timetable.ics'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: ImportScheduleButton()),
                  if (!kIsWeb) ...[
                    const SizedBox(width: 8),
                    Expanded(child: _RemindersButton(entries: entries)),
                  ],
                ],
              ),
            ),
            Expanded(
              child: _TimelineList(entries: entries, showDayHeaders: selectedDay == null),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(context: context, builder: (_) => const AddScheduleDialog()),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Vertical timeline layout — entries are already sorted by
/// (dayOfWeek, startTime) via filteredScheduleProvider. Grouped under a day
/// header when showing the whole week; shown as a flat timeline when a
/// single day is selected, since the header would be redundant.
class _TimelineList extends ConsumerWidget {
  const _TimelineList({required this.entries, required this.showDayHeaders});
  final List<ScheduleEntry> entries;
  final bool showDayHeaders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = <Widget>[];
    int? currentDay;
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      if (showDayHeaders && entry.dayOfWeek != currentDay) {
        currentDay = entry.dayOfWeek;
        if (items.isNotEmpty) items.add(const SizedBox(height: 12));
        items.add(_DayHeader(dayName: entry.dayName));
      }
      final isLastOfDay = i == entries.length - 1 || (showDayHeaders && entries[i + 1].dayOfWeek != entry.dayOfWeek);
      items.add(_TimelineTile(
        entry: entry,
        isLast: isLastOfDay,
        onTap: () => showDialog(context: context, builder: (_) => AddScheduleDialog(existing: entry)),
        onDelete: () => ref.read(timetableControllerProvider.notifier).delete(entry.scheduleId),
      ));
    }
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), children: items);
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.dayName});
  final String dayName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        dayName,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).campusTheme.accentGlow,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.entry, required this.isLast, required this.onTap, required this.onDelete});
  final ScheduleEntry entry;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  bool get _isOngoingNow {
    final now = DateTime.now();
    if (entry.dayOfWeek != now.weekday) return false;
    final nowMinutes = now.hour * 60 + now.minute;
    int minutesOf(String hhmm) {
      final parts = hhmm.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }

    return nowMinutes >= minutesOf(entry.startTime) && nowMinutes < minutesOf(entry.endTime);
  }

  @override
  Widget build(BuildContext context) {
    final campus = Theme.of(context).campusTheme;
    final ongoing = _isOngoingNow;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(
              entry.startTime,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: campus.textMuted),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(shape: BoxShape.circle, color: campus.accentGlow),
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: campus.subtleBorder)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CampusCardTile(
                decoration: campus.cardDecoration(glow: ongoing),
                radius: campus.cardRadius,
                child: ListTile(
                  onTap: onTap,
                  title: Text('${entry.courseCode} · ${entry.courseTitle}'),
                  subtitle: Text(
                    '${entry.lecturer} · ${entry.room ?? 'TBA'}\n${entry.startTime} - ${entry.endTime}',
                    style: TextStyle(color: campus.textMuted),
                  ),
                  isThreeLine: true,
                  trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RemindersButton extends ConsumerStatefulWidget {
  const _RemindersButton({required this.entries});
  final List<ScheduleEntry> entries;

  @override
  ConsumerState<_RemindersButton> createState() => _RemindersButtonState();
}

class _RemindersButtonState extends ConsumerState<_RemindersButton> {
  bool _busy = false;

  Future<void> _enableReminders() async {
    setState(() => _busy = true);
    try {
      final service = ref.read(notificationServiceProvider);
      await service.requestPermission();
      for (final entry in widget.entries) {
        await service.scheduleClassReminder(entry);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reminders set for ${widget.entries.length} classes')),
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
