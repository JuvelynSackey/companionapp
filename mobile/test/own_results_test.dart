import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/storage/local_prefs.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/data/api/grade_api.dart';
import 'package:mobile/data/models/course_grade.dart';
import 'package:mobile/features/analytics/analytics_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeGradeApi implements GradeApi {
  _FakeGradeApi(this.grades);
  final List<CourseGrade> grades;
  final added = <Map<String, Object>>[];
  final deleted = <int>[];

  @override
  Future<List<CourseGrade>> fetch() async => grades;

  @override
  Future<void> addMine({required String courseCode, required String courseTitle, required int creditHours, required double score, required String semester}) async {
    added.add({'courseCode': courseCode, 'courseTitle': courseTitle, 'creditHours': creditHours, 'score': score, 'semester': semester});
  }

  @override
  Future<void> deleteMine(int gradeId) async => deleted.add(gradeId);
}

CourseGrade _grade(int id, String code, {bool mine = false}) => CourseGrade(
      gradeId: id, courseCode: code, courseTitle: 'Course', creditHours: 3, score: 77, letterGrade: 'B+',
      semester: 'Semester 1 - 2025/2026', passed: true, selfReported: mine,
    );

Future<_FakeGradeApi> _pump(WidgetTester tester, List<CourseGrade> grades) async {
  tester.view.physicalSize = const Size(400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await LocalPrefs.create();
  final api = _FakeGradeApi(grades);
  await tester.pumpWidget(ProviderScope(
    overrides: [localPrefsProvider.overrideWithValue(prefs), gradeApiProvider.overrideWithValue(api)],
    child: MaterialApp(theme: AppTheme.light(), home: const AnalyticsScreen()),
  ));
  await tester.pumpAndSettle();
  return api;
}

void main() {
  test('a grade reads the server\'s selfReported flag, false when absent', () {
    final json = {
      'gradeId': 1, 'courseCode': 'DCIT 418', 'courseTitle': 'T', 'creditHours': 3, 'score': 77,
      'letterGrade': 'B+', 'semester': 'S', 'passed': true,
    };
    expect(CourseGrade.fromJson({...json, 'selfReported': true}).selfReported, isTrue);
    expect(CourseGrade.fromJson(json).selfReported, isFalse);
  });

  testWidgets('a self-entered result is labelled, shows no mark, and can be removed; an official one cannot', (tester) async {
    final api = await _pump(tester, [_grade(1, 'DCIT 401'), _grade(2, 'DCIT 418', mine: true)]);

    expect(find.textContaining('Entered by you'), findsOneWidget);
    expect(find.text('77%'), findsOneWidget, reason: 'only the official grade shows its mark');

    await tester.tap(find.textContaining('DCIT 401'));
    await tester.pumpAndSettle();
    expect(find.text('Remove this result?'), findsNothing);

    await tester.tap(find.textContaining('Entered by you'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await tester.pumpAndSettle();
    expect(api.deleted, [2]);
  });

  testWidgets('Add a result sends the course, credits, a mark inside the chosen grade and the semester', (tester) async {
    final api = await _pump(tester, [_grade(1, 'DCIT 401')]);

    await tester.tap(find.text('Add a result'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Course code'), 'dcit 428');
    await tester.enterText(find.widgetWithText(TextFormField, 'Course title'), 'Wireless Systems');
    await tester.enterText(find.widgetWithText(TextFormField, 'Year'), '2025/2026');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(api.added, [
      {'courseCode': 'dcit 428', 'courseTitle': 'Wireless Systems', 'creditHours': 3, 'score': 72.0, 'semester': 'Semester 1 - 2025/2026'},
    ]);
    expect(find.text('Result added. Your CGPA and FGPA now include it.'), findsOneWidget);
  });

  testWidgets('the form refuses a malformed course code or year', (tester) async {
    final api = await _pump(tester, []);
    await tester.tap(find.text('Add a result'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Course code'), 'Maths');
    await tester.enterText(find.widgetWithText(TextFormField, 'Course title'), 'Calculus');
    await tester.enterText(find.widgetWithText(TextFormField, 'Year'), '2025');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(api.added, isEmpty);
    expect(find.text('Like DCIT 418'), findsOneWidget);
    expect(find.text('Like 2025/2026'), findsOneWidget);
  });
}
