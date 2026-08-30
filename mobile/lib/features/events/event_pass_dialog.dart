import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../data/models/event_pass.dart';

class EventPassDialog extends StatelessWidget {
  const EventPassDialog({super.key, required this.pass});
  final EventPass pass;

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
            Icon(Icons.confirmation_number_outlined, size: 32, color: scheme.primary),
            const SizedBox(height: 8),
            Text('Event Pass', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Text(pass.eventTitle, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEE, MMM d · h:mm a').format(pass.eventDate.toLocal()),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (pass.venue != null) Text(pass.venue!, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border.all(color: scheme.outlineVariant), borderRadius: BorderRadius.circular(12)),
              child: QrImageView(data: pass.qrPayload, size: 160),
            ),
            const SizedBox(height: 16),
            Text(pass.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(pass.studentId, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(pass.passId, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.outline)),
            const SizedBox(height: 20),
            FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
          ],
        ),
      ),
    );
  }
}
