import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/dashboard/widgets/quick_access_grid.dart';

Widget _app({void Function(BuildContext, QuickAccessItem)? onOpen}) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: QuickAccessGrid(onOpen: onOpen))));

void main() {
  testWidgets('shows a labelled tile for every shortcut', (tester) async {
    await tester.pumpWidget(_app());

    for (final label in ['Campus map', 'Events', 'Clubs', 'Grades & GPA', 'AI Assistant', 'AI Tutor']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('tapping a tile opens that tile\'s item, not another one', (tester) async {
    final opened = <String>[];
    await tester.pumpWidget(_app(onOpen: (_, item) => opened.add(item.label)));

    await tester.tap(find.text('Grades & GPA'));
    await tester.tap(find.text('Campus map'));

    expect(opened, ['Grades & GPA', 'Campus map']);
  });
}
