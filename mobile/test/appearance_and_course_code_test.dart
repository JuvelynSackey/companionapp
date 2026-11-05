import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/theme/theme_mode_controller.dart';
import 'package:mobile/core/utils/course_code.dart';
import 'package:mobile/data/models/schedule_entry.dart';
import 'package:mobile/features/auth/welcome_screen.dart';

import 'support/local_prefs_fakes.dart';

void main() {
  group('course codes', () {
    test('are put in the printed form, capitals with one space', () {
      expect(normalizeCourseCode('dcit103'), 'DCIT 103');
      expect(normalizeCourseCode(' dcit   103 '), 'DCIT 103');
      expect(normalizeCourseCode('UGRC 110'), 'UGRC 110');
      expect(normalizeCourseCode('csc101a'), 'CSC 101A');
      expect(normalizeCourseCode('physics lab'), 'PHYSICS LAB', reason: 'not a code: only capitalised');
    });

    test('every timetable entry is stored that way, including ones already saved, and a blank room is no room', () {
      final saved = ScheduleEntry.fromJson({
        'scheduleId': 1, 'courseCode': 'dcit103', 'courseTitle': 'it', 'lecturer': '', 'dayOfWeek': 1,
        'dayName': 'Monday', 'startTime': '08:00', 'endTime': '09:00', 'room': '  ',
      });
      expect(saved.courseCode, 'DCIT 103');
      expect(saved.room, isNull);
      expect(ScheduleEntry.create(scheduleId: 2, courseCode: 'math 121', courseTitle: 'Algebra', lecturer: 'X', dayOfWeek: 2, startTime: '10:00', endTime: '11:00').courseCode, 'MATH 121');
    });
  });

  group('appearance', () {
    test('defaults to the phone setting and remembers a choice', () async {
      final prefs = await testLocalPrefs();
      final container = ProviderContainer(overrides: [localPrefsProvider.overrideWithValue(prefs)]);
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.system);
      await container.read(themeModeProvider.notifier).set(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(prefs.themeMode, 'dark', reason: 'saved for the next launch');

      final relaunched = ProviderContainer(overrides: [localPrefsProvider.overrideWithValue(prefs)]);
      addTearDown(relaunched.dispose);
      expect(relaunched.read(themeModeProvider), ThemeMode.dark);
    });

    testWidgets('the Appearance dialog switches the mode', (tester) async {
      final prefs = await testLocalPrefs();
      await tester.pumpWidget(ProviderScope(
        overrides: [localPrefsProvider.overrideWithValue(prefs)],
        child: MaterialApp(home: Builder(builder: (context) => TextButton(onPressed: () => showAppearanceDialog(context), child: const Text('open')))),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(prefs.themeMode, 'dark');
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      expect(prefs.themeMode, 'light');
    });

    testWidgets('the Welcome screen keeps its light look in dark mode', (tester) async {
      final prefs = await testLocalPrefs();
      await tester.pumpWidget(ProviderScope(
        overrides: [localPrefsProvider.overrideWithValue(prefs)],
        child: MaterialApp(themeMode: ThemeMode.dark, darkTheme: ThemeData.dark(), home: const WelcomeScreen()),
      ));
      // One frame is enough; the screen's Google check keeps animating here.
      await tester.pump();

      final context = tester.element(find.text('Get Started'));
      expect(Theme.of(context).brightness, Brightness.light);
    });
  });
}
