import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/features/exams/exams_screen.dart';

import 'support/local_prefs_fakes.dart';

String _inDays(int days) {
  final d = DateTime.now().add(Duration(days: days));
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

Map<String, Object> _exam(String id, String code, String title, int inDays) => {
      'id': id, 'courseCode': code, 'courseTitle': title, 'examDate': _inDays(inDays),
      'startTime': '09:00', 'endTime': '12:00', 'venue': 'Great Hall', 'seatRange': 'Seats 1-120',
    };

void main() {
  testWidgets('the next exam is shown once, codes are printed in capitals, and no card overflows', (tester) async {
    // Phone width; a layout overflow anywhere fails the test.
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final prefs = await testLocalPrefs({
      'local_exams_v1': jsonEncode([
        _exam('a', 'Dcit 101', 'Mathematics', 7),
        _exam('b', 'math121', 'Algebra', 14),
      ]),
    });
    await tester.pumpWidget(ProviderScope(
      overrides: [localPrefsProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: ExamsScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Next Exam'), findsOneWidget);
    expect(find.text('DCIT 101 · Mathematics'), findsOneWidget, reason: 'in the green card only, not again in the list');
    expect(find.text('Later exams'), findsOneWidget);
    expect(find.text('MATH 121 · Algebra'), findsOneWidget);
    expect(find.textContaining('Dcit'), findsNothing);

    // The next exam can still be edited and deleted, from the green card.
    expect(find.byTooltip('Edit exam'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete exam').first);
    await tester.pumpAndSettle();
    expect(find.text('DCIT 101 · Mathematics'), findsNothing);
    expect(find.text('MATH 121 · Algebra'), findsOneWidget, reason: 'now the next exam');
    expect(find.text('Later exams'), findsNothing);
  });
}
