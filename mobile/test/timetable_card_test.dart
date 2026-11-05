import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/features/timetable/timetable_screen.dart';

import 'support/local_prefs_fakes.dart';

Map<String, Object> _entry(int id, String code, String title, String lecturer, String? room, String start, String end) => {
      'scheduleId': id, 'courseCode': code, 'courseTitle': title, 'lecturer': lecturer, 'dayOfWeek': 1,
      'dayName': 'Monday', 'startTime': start, 'endTime': end, 'room': ?room,
    };

void main() {
  testWidgets('timetable cards: printed course codes, a soft "Room not set", and the time never cut off', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final prefs = await testLocalPrefs({
      'local_schedule_v1': jsonEncode([
        _entry(1, 'dcit103', 'it', '', null, '08:00', '09:00'),
        _entry(2, 'DCIT 201', 'Mathematics', 'Prof. A. Mensah', 'Balme Library Reading Room, second floor annexe', '10:00', '11:00'),
      ]),
    });
    await tester.pumpWidget(ProviderScope(
      overrides: [localPrefsProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: TimetableScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('DCIT 103 · it'), findsOneWidget, reason: 'a code saved as "dcit103" is shown in the printed form');
    expect(find.textContaining('TBA', findRichText: true), findsNothing);
    expect(find.text('Room not set', findRichText: true), findsOneWidget);

    // A long room wraps and the card grows with it, so the time below stays inside the card.
    for (final time in ['08:00 - 09:00', '10:00 - 11:00']) {
      final timeText = find.text(time);
      expect(timeText, findsOneWidget, reason: time);
      final card = find.ancestor(of: timeText, matching: find.byType(InkWell)).first;
      expect(tester.getRect(timeText).bottom, lessThanOrEqualTo(tester.getRect(card).bottom), reason: '$time is inside its card');
    }
  });
}
