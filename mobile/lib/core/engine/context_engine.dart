import 'dart:math';
import '../../data/models/campus_location.dart';
import '../../data/models/exam_countdown.dart';
import '../../data/models/schedule_entry.dart';
import '../utils/location_matching.dart';

enum ContextActionType { dailyBrief, scheduleConflict, classStartingSoon, examApproaching }

class CampusContextAction {
  const CampusContextAction({
    required this.type,
    required this.title,
    required this.description,
    this.location,
    this.minutesRemaining,
    this.estimatedWalkMinutes,
    required this.primaryButtonText,
  });

  final ContextActionType type;
  final String title;
  final String description;
  final String? location;
  final int? minutesRemaining;
  final int? estimatedWalkMinutes;
  final String primaryButtonText;

  bool get requiresImmediateDeparture =>
      minutesRemaining != null && estimatedWalkMinutes != null && estimatedWalkMinutes! >= (minutesRemaining! - 5);
}

/// Pure decision engine for the Dashboard's "Daily Brief" + smart action
/// cards. Travel-time is a straight-line (Haversine) estimate between a
/// class's matched CampusLocation and the *previous* class's matched
/// location — not real GPS (see the Phase 3 planning decision). A
/// ScheduleEntry only carries a freeform `room` string, not a location id,
/// so matching room text to a real CampusLocation is inherently best-effort
/// and can legitimately come back empty; when it does, the plain
/// "class starting soon" reminder still fires, just without a walk estimate.
class ContextEngine {
  ContextEngine._();

  static const _assumedWalkingMetersPerMinute = 75;
  static const _classStartingSoonWindowMinutes = 30;
  static const _examApproachingWindowHours = 48;

  static List<CampusContextAction> evaluate({
    required List<ScheduleEntry> todaysSchedule,
    required List<ExamCountdown> examCountdowns,
    required List<CampusLocation> locations,
    required DateTime now,
  }) {
    final sorted = [...todaysSchedule]..sort((a, b) => a.startTime.compareTo(b.startTime));

    return [
      _dailyBrief(sorted, examCountdowns),
      ..._conflicts(sorted),
      ..._classStartingSoon(sorted, locations, now),
      ..._examApproaching(examCountdowns),
    ];
  }

  static CampusContextAction _dailyBrief(List<ScheduleEntry> todaysSchedule, List<ExamCountdown> examCountdowns) {
    final nextExam = examCountdowns.where((e) => !e.isPast).firstOrNull;
    final classCount = todaysSchedule.length;
    final description = StringBuffer();
    description.write(classCount == 0 ? 'No classes today.' : '$classCount class${classCount == 1 ? '' : 'es'} today.');
    if (nextExam != null) {
      description.write(' Next exam: ${nextExam.exam.courseCode} (${nextExam.formattedDaysRemaining}).');
    }
    return CampusContextAction(
      type: ContextActionType.dailyBrief,
      title: 'Daily Brief',
      description: description.toString(),
      primaryButtonText: 'View Timetable',
    );
  }

  static List<CampusContextAction> _conflicts(List<ScheduleEntry> todaysSchedule) {
    final conflicts = <CampusContextAction>[];
    for (var i = 0; i < todaysSchedule.length; i++) {
      for (var j = i + 1; j < todaysSchedule.length; j++) {
        final a = todaysSchedule[i];
        final b = todaysSchedule[j];
        if (_timeRangesOverlap(a.startTime, a.endTime, b.startTime, b.endTime)) {
          conflicts.add(CampusContextAction(
            type: ContextActionType.scheduleConflict,
            title: 'Schedule Conflict',
            description: '${a.courseCode} and ${b.courseCode} overlap today.',
            location: '${a.room ?? 'TBA'} / ${b.room ?? 'TBA'}',
            primaryButtonText: 'Review Timetable',
          ));
        }
      }
    }
    return conflicts;
  }

  static List<CampusContextAction> _classStartingSoon(
    List<ScheduleEntry> todaysSchedule,
    List<CampusLocation> locations,
    DateTime now,
  ) {
    final nowMinutes = now.hour * 60 + now.minute;
    final actions = <CampusContextAction>[];

    for (var i = 0; i < todaysSchedule.length; i++) {
      final entry = todaysSchedule[i];
      final startMinutes = _minutesOf(entry.startTime);
      final minutesRemaining = startMinutes - nowMinutes;
      if (minutesRemaining < 0 || minutesRemaining > _classStartingSoonWindowMinutes) continue;

      final previous = i > 0 ? todaysSchedule[i - 1] : null;
      int? walkMinutes;
      if (previous?.room != null && entry.room != null) {
        final fromLoc = findLocationByName(previous!.room!, locations);
        final toLoc = findLocationByName(entry.room!, locations);
        if (fromLoc != null && toLoc != null && fromLoc.locationId != toLoc.locationId) {
          walkMinutes = _estimatedWalkMinutes(fromLoc, toLoc);
        }
      }

      actions.add(CampusContextAction(
        type: ContextActionType.classStartingSoon,
        title: '${entry.courseCode} starting soon',
        description: walkMinutes != null
            ? 'Starts in $minutesRemaining min · ~$walkMinutes min walk from ${previous!.room}'
            : 'Starts in $minutesRemaining min',
        location: entry.room,
        minutesRemaining: minutesRemaining,
        estimatedWalkMinutes: walkMinutes,
        primaryButtonText: 'View Class',
      ));
    }
    return actions;
  }

  static List<CampusContextAction> _examApproaching(List<ExamCountdown> examCountdowns) {
    return examCountdowns
        .where((e) => !e.isPast && e.daysRemaining * 24 <= _examApproachingWindowHours)
        .map((e) => CampusContextAction(
              type: ContextActionType.examApproaching,
              title: 'Exam approaching: ${e.exam.courseCode}',
              description: '${e.formattedExamDate} at ${e.exam.startTime} — ${e.formattedDaysRemaining}',
              location: e.exam.venue,
              primaryButtonText: 'View Exam',
            ))
        .toList();
  }

  static bool _timeRangesOverlap(String start1, String end1, String start2, String end2) {
    final s1 = _minutesOf(start1);
    final e1 = _minutesOf(end1);
    final s2 = _minutesOf(start2);
    final e2 = _minutesOf(end2);
    return s1 < e2 && s2 < e1;
  }

  static int _minutesOf(String hhmm) {
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  static int _estimatedWalkMinutes(CampusLocation from, CampusLocation to) {
    final meters = _haversineMeters(from.latitude, from.longitude, to.latitude, to.longitude);
    return (meters / _assumedWalkingMetersPerMinute).ceil();
  }

  static double _haversineMeters(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static double _degToRad(double deg) => deg * (pi / 180);
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
