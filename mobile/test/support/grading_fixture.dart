import 'dart:convert';
import 'dart:io';

/// docs/grading-scale-ug.json, the reference the backend tests also read.
/// Tests run with mobile/ as the working directory.
Map<String, dynamic> loadGradingFixture() {
  for (final path in ['../docs/grading-scale-ug.json', 'docs/grading-scale-ug.json']) {
    final file = File(path);
    if (file.existsSync()) return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }
  throw StateError('docs/grading-scale-ug.json not found (run flutter test from mobile/)');
}
