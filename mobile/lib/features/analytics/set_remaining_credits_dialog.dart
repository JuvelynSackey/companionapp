import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';

class SetRemainingCreditsDialog extends ConsumerStatefulWidget {
  const SetRemainingCreditsDialog({super.key, this.initialValue});

  final int? initialValue;

  @override
  ConsumerState<SetRemainingCreditsDialog> createState() => _SetRemainingCreditsDialogState();
}

class _SetRemainingCreditsDialogState extends ConsumerState<SetRemainingCreditsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.initialValue?.toString() ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final value = int.parse(_controller.text.trim());
    await ref.read(localPrefsProvider).setRemainingCredits(value);
    ref.invalidate(localPrefsProvider);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Remaining Credit Hours'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Credit hours left until graduation'),
          validator: (v) {
            final n = int.tryParse(v?.trim() ?? '');
            if (n == null || n <= 0) return 'Enter a whole number greater than 0';
            return null;
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
