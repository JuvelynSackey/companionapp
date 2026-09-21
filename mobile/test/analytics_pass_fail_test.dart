import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/storage/local_prefs.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/theme/campus_companion_theme.dart';
import 'package:mobile/data/api/grade_api.dart';
import 'package:mobile/data/models/course_grade.dart';
import 'package:mobile/features/analytics/analytics_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/grading_fixture.dart';

class _FakeGradeApi implements GradeApi {
  _FakeGradeApi(this.grades);
  final List<CourseGrade> grades;

  @override
  Future<List<CourseGrade>> fetch() async => grades;
}

/// The app does not decide pass/fail itself: it shows the server's `passed`
/// flag. What the fixture (docs/grading-scale-ug.json) defines as failing is
/// what the backend tests check the server sends, so this closes the loop by
/// checking the screen reacts to that flag.
void main() {
  final scale = (loadGradingFixture()['scale'] as List).cast<Map<String, dynamic>>();

  testWidgets('every band of the UG scale is coloured by its passes flag (E and F in the error colour)', (tester) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await LocalPrefs.create();
    final grades = [
      for (final band in scale)
        CourseGrade(
          gradeId: 1,
          courseCode: 'GR-${band['letter']}',
          courseTitle: 'Course',
          creditHours: 3,
          score: (band['min'] as num).toDouble(),
          letterGrade: band['letter'] as String,
          semester: 'Semester 1',
          passed: band['passes'] as bool,
        ),
    ];

    final theme = AppTheme.light();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        localPrefsProvider.overrideWithValue(prefs),
        gradeApiProvider.overrideWithValue(_FakeGradeApi(grades)),
      ],
      child: MaterialApp(theme: theme, home: const AnalyticsScreen()),
    ));
    await tester.pumpAndSettle();

    final passColor = theme.campusTheme.accentGlow;
    final failColor = theme.colorScheme.error;
    expect(passColor, isNot(failColor), reason: 'the two states must look different');

    for (final band in scale) {
      final letter = band['letter'] as String;
      final tile = find.widgetWithText(ListTile, 'GR-$letter · Course');
      expect(tile, findsOneWidget, reason: 'row for $letter');

      final letterText = tester.widget<Text>(find.descendant(of: tile, matching: find.text(letter)));
      expect(
        letterText.style?.color,
        (band['passes'] as bool) ? passColor : failColor,
        reason: '$letter passes=${band['passes']}',
      );
    }
  });
}
