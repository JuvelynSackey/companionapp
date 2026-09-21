import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/student_hub_models.dart';
import '../auth/session_controller.dart';
import 'student_hub_providers.dart';

class ReportLostFoundDialog extends ConsumerStatefulWidget {
  const ReportLostFoundDialog({super.key});

  @override
  ConsumerState<ReportLostFoundDialog> createState() => _ReportLostFoundDialogState();
}

class _ReportLostFoundDialogState extends ConsumerState<ReportLostFoundDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactController = TextEditingController();
  final _rewardController = TextEditingController();
  LostFoundStatus _status = LostFoundStatus.lost;
  LostFoundCategory _category = LostFoundCategory.other;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _contactController.dispose();
    _rewardController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(sessionControllerProvider).valueOrNull;

    final item = LostFoundItem(
      id: 'user_${DateTime.now().microsecondsSinceEpoch}',
      title: _titleController.text.trim(),
      category: _category,
      status: _status,
      campusLocation: _locationController.text.trim(),
      dateReported: 'Just now',
      reporterName: user?.fullName ?? 'Student',
      contactPhone: _contactController.text.trim(),
      description: _descriptionController.text.trim(),
      rewardGhs: _status == LostFoundStatus.lost && _rewardController.text.trim().isNotEmpty
          ? double.tryParse(_rewardController.text.trim())
          : null,
    );

    await ref.read(lostFoundControllerProvider.notifier).report(item);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report an Item'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<LostFoundStatus>(
                segments: const [
                  ButtonSegment(value: LostFoundStatus.lost, label: Text('I Lost This')),
                  ButtonSegment(value: LostFoundStatus.found, label: Text('I Found This')),
                ],
                selected: {_status},
                onSelectionChanged: (selection) => setState(() => _status = selection.first),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Item title'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<LostFoundCategory>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  for (final category in LostFoundCategory.values)
                    DropdownMenuItem(value: category, child: Text(category.label)),
                ],
                onChanged: (value) => setState(() => _category = value!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Campus location'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Your contact phone'),
                validator: (v) => (v == null || v.trim().length < 9) ? 'Enter a valid phone number' : null,
              ),
              if (_status == LostFoundStatus.lost) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _rewardController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Reward pledge in GH₵ (optional)'),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Submit Report')),
      ],
    );
  }
}
