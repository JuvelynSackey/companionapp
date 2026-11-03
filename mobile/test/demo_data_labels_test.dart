import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/storage/local_prefs.dart';
import 'package:mobile/features/resources/resources_screen.dart';
import 'package:mobile/features/student_hub/student_hub_screen.dart';
import 'package:mobile/widgets/demo_data_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sample data and simulated actions must never pass for the real thing:
/// every screen built on fixtures says so, and a document "request" says it
/// was not sent anywhere.
Future<Widget> _app(Widget screen) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await LocalPrefs.create();
  return ProviderScope(
    overrides: [localPrefsProvider.overrideWithValue(prefs)],
    child: MaterialApp(home: screen),
  );
}

void _tallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('Student Hub says its data is a demo and that payments are simulated', (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(await _app(const StudentHubScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(DemoDataBanner), findsOneWidget);
    expect(find.textContaining('payments are simulated', findRichText: true), findsOneWidget);
  });

  testWidgets('Resources labels its sample tabs, and a document request says nothing was sent', (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(await _app(const ResourcesScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(DemoDataBanner), findsOneWidget, reason: 'Libraries tab');

    await tester.tap(find.text('Past Papers'));
    await tester.pumpAndSettle();
    expect(find.textContaining('sample list of past papers', findRichText: true), findsOneWidget);

    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nothing is sent to Academic Affairs', findRichText: true), findsOneWidget);

    await tester.tap(find.text('Request').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Not sent to Academic Affairs'), findsOneWidget);
    expect(find.textContaining('Nothing was sent'), findsOneWidget);
    expect(find.textContaining('collect the certified copy'), findsNothing);
  });
}
