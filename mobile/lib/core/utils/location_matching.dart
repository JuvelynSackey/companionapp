import '../../data/models/campus_location.dart';

/// Best-effort text-to-CampusLocation matching, shared by ContextEngine
/// (schedule room -> location) and Exam Mode (exam venue -> location).
/// Neither ScheduleEntry.room nor Exam.venue carry a real location id, so
/// this is inherently a substring match, not a guaranteed lookup.
CampusLocation? findLocationByName(String text, List<CampusLocation> locations) {
  final needle = text.toLowerCase().trim();
  if (needle.isEmpty) return null;
  for (final loc in locations) {
    final name = loc.name.toLowerCase();
    if (name == needle || name.contains(needle) || needle.contains(name)) return loc;
  }
  return null;
}
