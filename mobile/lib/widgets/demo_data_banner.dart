import 'package:flutter/material.dart';

/// A strip at the top of a screen or tab whose content is sample data built
/// into the app (or a simulated action), not live data from the backend, so
/// a student never mistakes it for the real thing.
class DemoDataBanner extends StatelessWidget {
  const DemoDataBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final color = Colors.amber.shade900;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.amber.withValues(alpha: 0.14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.science_outlined, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: 'Demo data. ', style: TextStyle(fontWeight: FontWeight.w700, color: color)),
                TextSpan(text: message, style: TextStyle(color: color)),
              ]),
              style: const TextStyle(fontSize: 12.5, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
