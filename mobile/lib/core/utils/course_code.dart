/// Puts a course code in the University's printed form: capitals, with one
/// space between the subject letters and the number ("dcit103" and
/// "DCIT  103" both become "DCIT 103"). Anything that does not look like a
/// code is only trimmed and upper-cased.
String normalizeCourseCode(String raw) {
  final code = raw.trim().replaceAll(RegExp(r'\s+'), ' ').toUpperCase();
  final match = RegExp(r'^([A-Z]+) ?(\d+[A-Z]?)$').firstMatch(code);
  return match == null ? code : '${match.group(1)} ${match.group(2)}';
}
