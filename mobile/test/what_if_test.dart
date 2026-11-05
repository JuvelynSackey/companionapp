import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/data/models/course_grade.dart';
import 'package:mobile/data/models/institution_profile.dart';
import 'package:mobile/features/analytics/analytics_providers.dart';
import 'package:mobile/features/analytics/what_if_screen.dart';

import 'support/local_prefs_fakes.dart';

var _id = 0;
CourseGrade _g(String code, double score, {int credits = 3}) => CourseGrade(
      gradeId: _id++, courseCode: code, courseTitle: code, creditHours: credits, score: score,
      letterGrade: '', semester: 'Semester 1 - 2025/2026', passed: score >= 45,
    );

void main() {
  // One C (2.0) at each level: CGPA and FGPA are both 2.00 to start.
  final current = [_g('DCIT 101', 62), _g('DCIT 201', 62), _g('DCIT 301', 62), _g('DCIT 401', 62)];

  test('planned grades are added at their letter\'s points, and Level 400 counts double in the FGPA', () {
    final after = projectWithPlanned(current, [WhatIfCourse(code: 'DCIT 418', letter: 'A')], InstitutionRegistry.ug);
    // CGPA: (4 x 6 + 12) / 15 = 2.40. Level 400 GPA: (6 + 12) / 6 = 3.00,
    // so FGPA = (2 + 2 + 2x2 + 2x3) / 6 = 2.33.
    expect(after.scoreValue.toStringAsFixed(2), '2.40');
    expect(after.fgpa!.toStringAsFixed(2), '2.33');
  });

  test('blank rows are ignored and every letter maps inside its UG band', () {
    final same = projectWithPlanned(current, [WhatIfCourse(code: '  ')], InstitutionRegistry.ug);
    expect(same.scoreValue.toStringAsFixed(2), '2.00');
    expect(whatIfLetterMarks, {'A': 85, 'B+': 77, 'B': 72, 'C+': 67, 'C': 62, 'D+': 57, 'D': 52, 'E': 47, 'F': 30});
  });

  testWidgets('the screen starts from ungraded timetable courses and fits a phone screen', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final prefs = await testLocalPrefs({
      'selected_institution_id': InstitutionRegistry.ug.id,
      'local_schedule_v1':
          '[{"scheduleId":1,"courseCode":"DCIT 418","courseTitle":"Security","lecturer":"","dayOfWeek":1,"dayName":"Monday","startTime":"08:30","endTime":"10:20","room":null},'
          '{"scheduleId":2,"courseCode":"DCIT 401","courseTitle":"Ethics","lecturer":"","dayOfWeek":2,"dayName":"Tuesday","startTime":"08:30","endTime":"10:20","room":null}]',
    });
    await tester.pumpWidget(ProviderScope(
      overrides: [
        localPrefsProvider.overrideWithValue(prefs),
        gradesProvider.overrideWith((ref) async => current),
      ],
      child: const MaterialApp(home: WhatIfScreen()),
    ));
    await tester.pumpAndSettle();

    final codes = [for (final f in tester.widgetList<EditableText>(find.byType(EditableText))) f.controller.text];
    expect(codes, ['DCIT 418'], reason: 'only the ungraded timetable course is pre-filled');
    expect(find.text('Now'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'no overflow at 360 px');
  });
}
