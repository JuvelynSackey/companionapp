import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/student_hub_models.dart';
import '../auth/session_controller.dart';
import '../onboarding/institution_controller.dart';
import 'momo_receipt_dialog.dart';
import 'student_hub_providers.dart';

/// Simulated MoMo checkout — no real payment gateway is connected here.
/// The confirm button and receipt both say so explicitly, matching the
/// project's requirement to distinguish simulated transactions from real
/// financial integration.
class MomoPaymentDialog extends ConsumerStatefulWidget {
  const MomoPaymentDialog({super.key, required this.due});

  final CampusDue due;

  @override
  ConsumerState<MomoPaymentDialog> createState() => _MomoPaymentDialogState();
}

class _MomoPaymentDialogState extends ConsumerState<MomoPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  MoMoProvider _provider = MoMoProvider.mtnMomo;
  bool _isPaying = false;

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _confirmPay() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isPaying = true);

    final user = ref.read(sessionControllerProvider).valueOrNull;
    final institution = ref.read(institutionControllerProvider);
    final localProfile = ref.read(localProfileControllerProvider);
    final studentId = localProfile.studentId.isNotEmpty
        ? localProfile.studentId
        : '${institution.shortCode}-${(user?.userId ?? 0).toString().padLeft(6, '0')}';

    await Future<void>.delayed(const Duration(milliseconds: 900));

    final receipt = await ref.read(momoReceiptsControllerProvider.notifier).pay(
          due: widget.due,
          payerName: user?.fullName ?? 'Student',
          studentId: studentId,
          momoNumber: _numberController.text.trim(),
          provider: _provider,
        );

    if (!mounted) return;
    Navigator.of(context).pop();
    showDialog<void>(context: context, builder: (_) => MomoReceiptDialog(receipt: receipt));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pay with Mobile Money'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.due.title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'GH₵ ${widget.due.amountGhs.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MoMoProvider>(
              initialValue: _provider,
              decoration: const InputDecoration(labelText: 'Provider'),
              items: [
                for (final provider in MoMoProvider.values)
                  DropdownMenuItem(value: provider, child: Text(provider.label)),
              ],
              onChanged: _isPaying ? null : (value) => setState(() => _provider = value!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _numberController,
              enabled: !_isPaying,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile Money number', hintText: '024 xxx xxxx'),
              validator: (v) => (v == null || v.trim().length < 9) ? 'Enter a valid phone number' : null,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Simulated payment for demonstration — no real money moves.',
                      style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _isPaying ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: _isPaying ? null : _confirmPay,
          child: _isPaying
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Confirm Payment'),
        ),
      ],
    );
  }
}
