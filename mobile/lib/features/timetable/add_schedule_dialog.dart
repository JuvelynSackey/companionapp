import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/schedule_entry.dart';
import 'timetable_providers.dart';

const _dayLabels = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

/// Manual entry for a student's own timetable — no backend course catalog
/// involved anymore, since the Timetable is now fully student-managed.
class AddScheduleDialog extends ConsumerStatefulWidget {
  const AddScheduleDialog({super.key, this.existing});
  final ScheduleEntry? existing;

  @override
  ConsumerState<AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends ConsumerState<AddScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _courseCodeController = TextEditingController(text: widget.existing?.courseCode ?? '');
  late final _courseTitleController = TextEditingController(text: widget.existing?.courseTitle ?? '');
  late final _lecturerController = TextEditingController(text: widget.existing?.lecturer ?? '');
  late final _roomController = TextEditingController(text: widget.existing?.room ?? '');
  late int _dayOfWeek = widget.existing?.dayOfWeek ?? 1;
  late TimeOfDay _startTime = _parseTime(widget.existing?.startTime) ?? const TimeOfDay(hour: 9, minute: 0);
  late TimeOfDay _endTime = _parseTime(widget.existing?.endTime) ?? const TimeOfDay(hour: 10, minute: 0);
  bool _submitting = false;

  static TimeOfDay? _parseTime(String? raw) {
    if (raw == null) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _courseCodeController.dispose();
    _courseTitleController.dispose();
    _lecturerController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final controller = ref.read(timetableControllerProvider.notifier);
      if (widget.existing != null) {
        await controller.update(widget.existing!.copyWith(
          courseCode: _courseCodeController.text.trim(),
          courseTitle: _courseTitleController.text.trim(),
          lecturer: _lecturerController.text.trim(),
          dayOfWeek: _dayOfWeek,
          startTime: _fmt(_startTime),
          endTime: _fmt(_endTime),
          room: _roomController.text.trim().isEmpty ? null : _roomController.text.trim(),
        ));
      } else {
        await controller.add(
          courseCode: _courseCodeController.text.trim(),
          courseTitle: _courseTitleController.text.trim(),
          lecturer: _lecturerController.text.trim(),
          dayOfWeek: _dayOfWeek,
          startTime: _fmt(_startTime),
          endTime: _fmt(_endTime),
          room: _roomController.text.trim().isEmpty ? null : _roomController.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing != null ? 'Edit Class' : 'Add Class'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _courseCodeController,
                decoration: const InputDecoration(labelText: 'Course Code'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _courseTitleController,
                decoration: const InputDecoration(labelText: 'Course Title'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lecturerController,
                decoration: const InputDecoration(labelText: 'Lecturer (optional)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _dayOfWeek,
                decoration: const InputDecoration(labelText: 'Day'),
                items: List.generate(7, (i) => DropdownMenuItem(value: i + 1, child: Text(_dayLabels[i]))),
                onChanged: (v) => setState(() => _dayOfWeek = v ?? 1),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showTimePicker(context: context, initialTime: _startTime);
                        if (picked != null) setState(() => _startTime = picked);
                      },
                      child: Text('Start: ${_fmt(_startTime)}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showTimePicker(context: context, initialTime: _endTime);
                        if (picked != null) setState(() => _endTime = picked);
                      },
                      child: Text('End: ${_fmt(_endTime)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _roomController,
                decoration: const InputDecoration(labelText: 'Room (optional)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _submitting ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.existing != null ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
