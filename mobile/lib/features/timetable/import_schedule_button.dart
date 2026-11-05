import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../core/utils/schedule_parser.dart';
import '../../data/models/schedule_entry.dart';
import 'timetable_providers.dart';

class ImportScheduleButton extends ConsumerStatefulWidget {
  const ImportScheduleButton({super.key});

  @override
  ConsumerState<ImportScheduleButton> createState() => _ImportScheduleButtonState();
}

class _ImportScheduleButtonState extends ConsumerState<ImportScheduleButton> {
  bool _busy = false;

  static ScheduleEntry _withId(ScheduleEntry entry, int id) => ScheduleEntry.create(
        scheduleId: id,
        courseCode: entry.courseCode,
        courseTitle: entry.courseTitle,
        lecturer: entry.lecturer,
        dayOfWeek: entry.dayOfWeek,
        startTime: entry.startTime,
        endTime: entry.endTime,
        room: entry.room,
      );

  Future<void> _import() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ics', 'csv'],
    );
    if (files.isEmpty) return;
    final picked = files.first;

    setState(() => _busy = true);
    try {
      final content = utf8.decode(await picked.readAsBytes());
      final isIcs = picked.name.toLowerCase().endsWith('.ics');
      // Placeholder ids here — real ones are assigned below once we know
      // how many entries actually parsed successfully.
      final parsed = isIcs
          ? ScheduleParser.parseIcs(content, nextId: () => 0)
          : ScheduleParser.parseCsv(content, nextId: () => 0);

      if (parsed.entries.isNotEmpty) {
        final repo = ref.read(localScheduleRepositoryProvider);
        final withRealIds = <ScheduleEntry>[];
        for (final entry in parsed.entries) {
          withRealIds.add(_withId(entry, await repo.nextId()));
        }
        await ref.read(timetableControllerProvider.notifier).importEntries(withRealIds);
      }

      if (mounted) _showResult(imported: parsed.entries.length, errors: parsed.errors);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showResult({required int imported, required List<String> errors}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import Result'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$imported class${imported == 1 ? '' : 'es'} imported.'),
              if (errors.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Issues:', style: TextStyle(fontWeight: FontWeight.bold)),
                for (final e in errors) Text('• $e'),
              ],
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: _busy
          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.upload_file_outlined, size: 18),
      label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Import', maxLines: 1, softWrap: false)),
      onPressed: _busy ? null : _import,
    );
  }
}
