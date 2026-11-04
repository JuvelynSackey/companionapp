import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/data/models/institution_profile.dart';
import 'package:mobile/features/resources/resources_screen.dart';

import 'support/local_prefs_fakes.dart';

void main() {
  testWidgets('Resources offers only the real parts: official portals and documents, and quizzes', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final prefs = await testLocalPrefs({'selected_institution_id': InstitutionRegistry.ug.id});
    await tester.pumpWidget(ProviderScope(
      overrides: [localPrefsProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: ResourcesScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(Tab), findsNWidgets(2));
    for (final removed in ['Libraries', 'Past Papers', 'Documents']) {
      expect(find.text(removed), findsNothing, reason: removed);
    }
    expect(find.text('Sakai LMS'), findsOneWidget);
    expect(find.text('Regulations for Junior Members (2017)'), findsOneWidget);
  });

  test('the regulations entry points at the official PDF on ug.edu.gh', () {
    final regulations = InstitutionRegistry.ug.portals.singleWhere((p) => p.category == officialDocumentsCategory);
    expect(regulations.url, 'https://www.ug.edu.gh/sites/default/files/UG_Regulations_for_Junior_Members-2017.pdf');
  });
}
