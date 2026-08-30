import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/exam.dart';
import 'exams_providers.dart';

class AddExamDialog extends ConsumerStatefulWidget {
  const AddExamDialog({super.key, this.existing});

  final Exam? existing;

  @override
  ConsumerState<AddExamDialog> createState() => _AddExamDialogState();
}

class _AddExamDialogState extends ConsumerState<AddExamDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _courseCodeController = TextEditingController(text: widget.existing?.courseCode ?? '');
  late final _courseTitleController = TextEditingController(text: widget.existing?.courseTitle ?? '');
  late final _venueController = TextEditingController(text: widget.existing?.venue ?? '');
  late final _seatRangeController = TextEditingController(text: widget.existing?.seatRange ?? '');
  late final _invigilatorController = TextEditingController(text: widget.existing?.invigilator ?? '');
  late DateTime _examDate = widget.existing != null ? DateTime.parse(widget.existing!.examDate) : DateTime.now().add(const Duration(days: 7));
  late TimeOfDay _startTime = _parseTime(widget.existing?.startTime) ?? const TimeOfDay(hour: 9, minute: 0);
  late TimeOfDay _endTime = _parseTime(widget.existing?.endTime) ?? const TimeOfDay(hour: 12, minute: 0);

  static TimeOfDay? _parseTime(String? raw) {
    if (raw == null) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _fmtTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  String _fmtDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _courseCodeController.dispose();
    _courseTitleController.dispose();
    _venueController.dispose();
    _seatRangeController.dispose();
    _invigilatorController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final exam = Exam(
      id: widget.existing?.id ?? '',
      courseCode: _courseCodeController.text.trim(),
      courseTitle: _courseTitleController.text.trim(),
      examDate: _fmtDate(_examDate),
      startTime: _fmtTime(_startTime),
      endTime: _fmtTime(_endTime),
      venue: _venueController.text.trim(),
      seatRange: _seatRangeController.text.trim(),
      invigilator: _invigilatorController.text.trim(),
    );
    if (widget.existing != null) {
      await ref.read(examsControllerProvider.notifier).update(exam);
    } else {
      await ref.read(examsControllerProvider.notifier).add(exam);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing != null ? 'Edit Exam' : 'Add Exam'),
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
              OutlinedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _examDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (picked != null) setState(() => _examDate = picked);
                },
                child: Text('Date: ${_fmtDate(_examDate)}'),
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
                      child: Text('Start: ${_fmtTime(_startTime)}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showTimePicker(context: context, initialTime: _endTime);
                        if (picked != null) setState(() => _endTime = picked);
                      },
                      child: Text('End: ${_fmtTime(_endTime)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _venueController,
                decoration: const InputDecoration(labelText: 'Venue'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _seatRangeController,
                decoration: const InputDecoration(labelText: 'Seat Range (optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _invigilatorController,
                decoration: const InputDecoration(labelText: 'Invigilator (optional)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: Text(widget.existing != null ? 'Save' : 'Add')),
      ],
    );
  }
}
