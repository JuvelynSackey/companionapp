import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/student_hub_models.dart';

class MomoReceiptDialog extends StatelessWidget {
  const MomoReceiptDialog({super.key, required this.receipt});

  final MoMoReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 40, color: Colors.green.shade600),
            const SizedBox(height: 8),
            Text('Payment Successful', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
              child: Text(
                'SIMULATED PAYMENT — NOT A REAL TRANSACTION',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border.all(color: scheme.outlineVariant), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReceiptRow('Item', receipt.itemTitle),
                  _ReceiptRow('Amount', 'GH₵ ${receipt.amountGhs.toStringAsFixed(2)}'),
                  _ReceiptRow('Provider', receipt.provider.label),
                  _ReceiptRow('MoMo Number', receipt.momoNumber),
                  _ReceiptRow('Payer', receipt.payerName),
                  _ReceiptRow('Student ID', receipt.studentId),
                  _ReceiptRow('Date', DateFormat('EEE, MMM d · h:mm a').format(receipt.timestamp)),
                  _ReceiptRow('Reference', receipt.transactionRef),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
