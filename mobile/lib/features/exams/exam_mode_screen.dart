import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/campus_companion_theme.dart';
import '../../core/utils/location_matching.dart';
import '../../core/utils/schedule_time_math.dart';
import '../../data/models/exam.dart';
import '../../widgets/open_in_maps.dart';
import '../locations/locations_providers.dart';

/// Manually triggered from an exam card — not auto-launched. A full-screen
/// overlay showing exactly what a student needs in the last stretch before
/// an exam: venue, seat range, invigilator, the exam's own rules text (the
/// only "materials" data that actually exists — Exam has no structured
/// permitted/prohibited-items field), and a live countdown.
class ExamModeScreen extends ConsumerStatefulWidget {
  const ExamModeScreen({super.key, required this.exam});
  final Exam exam;

  @override
  ConsumerState<ExamModeScreen> createState() => _ExamModeScreenState();
}

class _ExamModeScreenState extends ConsumerState<ExamModeScreen> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exam = widget.exam;
    final examStart = ScheduleTimeMath.combine(DateTime.parse(exam.examDate), exam.startTime);
    final remaining = examStart.difference(_now);
    final locations = ref.watch(allLocationsProvider).valueOrNull ?? const [];
    final matchedVenue = findLocationByName(exam.venue, locations);

    return Scaffold(
      backgroundColor: CampusColors.slate900,
      appBar: AppBar(
        backgroundColor: CampusColors.slate900,
        foregroundColor: Colors.white,
        title: const Text('Exam Mode'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(exam.courseCode, style: const TextStyle(color: Colors.white70, fontSize: 16)),
              Text(exam.courseTitle, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              Center(child: _Countdown(remaining: remaining)),
              const SizedBox(height: 32),
              _InfoRow(icon: Icons.place_outlined, label: 'Venue', value: exam.venue),
              if (exam.seatRange.isNotEmpty) _InfoRow(icon: Icons.event_seat_outlined, label: 'Seat Range', value: exam.seatRange),
              if (exam.invigilator.isNotEmpty) _InfoRow(icon: Icons.supervisor_account_outlined, label: 'Invigilator', value: exam.invigilator),
              _InfoRow(icon: Icons.schedule_outlined, label: 'Time', value: '${exam.startTime} - ${exam.endTime}'),
              if (matchedVenue != null) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CampusColors.brandLight,
                    side: const BorderSide(color: CampusColors.brandLight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.directions_outlined),
                  label: const Text('Navigate to Venue'),
                  onPressed: () => openInMaps(context, label: exam.venue, latitude: matchedVenue.latitude, longitude: matchedVenue.longitude),
                ),
              ],
              const SizedBox(height: 32),
              if (exam.rules.isNotEmpty) ...[
                const Text('Rules & Permitted Materials', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CampusColors.slate800,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x1FFFFFFF)),
                  ),
                  child: Text(exam.rules, style: const TextStyle(color: Colors.white70, height: 1.5)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Countdown extends StatelessWidget {
  const _Countdown({required this.remaining});
  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final isPast = remaining.isNegative;
    final abs = remaining.abs();
    final days = abs.inDays;
    final hours = abs.inHours % 24;
    final minutes = abs.inMinutes % 60;
    final seconds = abs.inSeconds % 60;

    return Column(
      children: [
        Text(
          isPast ? 'Exam has started' : 'Starts in',
          style: TextStyle(color: isPast ? Colors.redAccent : CampusColors.brandLight, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(
          days > 0
              ? '${days}d ${hours}h ${minutes}m'
              : '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
          style: TextStyle(
            color: isPast ? Colors.redAccent : Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
