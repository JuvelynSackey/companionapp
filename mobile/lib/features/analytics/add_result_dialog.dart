import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/core_providers.dart';
import 'what_if_screen.dart' show whatIfLetterMarks;

/// "Add a result": the student records one of their own results. It is saved
/// to their account marked as entered by them (never as an official grade),
/// and the CGPA, FGPA and semester view update with it. Pops true when saved.
class AddResultDialog extends ConsumerStatefulWidget {
  const AddResultDialog({super.key});

  @override
  ConsumerState<AddResultDialog> createState() => _AddResultDialogState();
}

class _AddResultDialogState extends ConsumerState<AddResultDialog> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _title = TextEditingController();
  final _year = TextEditingController(text: _currentAcademicYear());
  int _credits = 3;
  int _semester = 1;
  String _letter = 'B';
  bool _saving = false;
  String? _error;

  /// "2026/2027" from September, otherwise "2025/2026".
  static String _currentAcademicYear() {
    final now = DateTime.now();
    final start = now.month >= 9 ? now.year : now.year - 1;
    return '$start/${start + 1}';
  }

  @override
  void dispose() {
    _code.dispose();
    _title.dispose();
    _year.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(gradeApiProvider).addMine(
            courseCode: _code.text.trim(),
            courseTitle: _title.text.trim(),
            creditHours: _credits,
            score: whatIfLetterMarks[_letter]!,
            semester: 'Semester $_semester - ${_year.text.trim()}',
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add a result'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _code,
                decoration: const InputDecoration(labelText: 'Course code', hintText: 'DCIT 418'),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => RegExp(r'^\s*[A-Za-z]+\s*\d{3}[A-Za-z]?\s*$').hasMatch(v ?? '') ? null : 'Like DCIT 418',
              ),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Course title'),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v ?? '').trim().length < 2 ? 'Enter the course title' : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _semester,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Semester'),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('First')),
                        DropdownMenuItem(value: 2, child: Text('Second')),
                      ],
                      onChanged: (v) => setState(() => _semester = v ?? 1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _year,
                      decoration: const InputDecoration(labelText: 'Year', hintText: '2025/2026'),
                      validator: (v) => RegExp(r'^\d{4}/\d{4}$').hasMatch((v ?? '').trim()) ? null : 'Like 2025/2026',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _credits,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Credits'),
                      items: [for (final c in [1, 2, 3, 4, 6]) DropdownMenuItem(value: c, child: Text('$c'))],
                      onChanged: (v) => setState(() => _credits = v ?? 3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _letter,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Grade'),
                      items: [for (final l in whatIfLetterMarks.keys) DropdownMenuItem(value: l, child: Text(l))],
                      onChanged: (v) => setState(() => _letter = v ?? 'B'),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _saving ? null : _save, child: const Text('Save')),
      ],
    );
  }
}
