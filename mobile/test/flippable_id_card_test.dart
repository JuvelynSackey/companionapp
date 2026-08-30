import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/profile/widgets/flippable_id_card.dart';

void main() {
  // Pumped inside a SingleChildScrollView, matching how DigitalIdScreen
  // actually uses this widget (unbounded height ancestor) — a Column with
  // a Spacer inside front/back content would throw a RenderFlex
  // "unbounded height" error in exactly this context, which is the real
  // regression class this test guards against (see the fix removing
  // Spacer() from _IdCardBack in digital_id_screen.dart).
  Widget harness(Widget front, Widget back) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: FlippableIdCard(front: front, back: back),
          ),
        ),
      );

  testWidgets('shows the front by default and no layout exceptions occur', (tester) async {
    await tester.pumpWidget(harness(const Text('FRONT'), const Text('BACK')));
    await tester.pumpAndSettle();

    expect(find.text('FRONT'), findsOneWidget);
    expect(find.text('BACK'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('flips to the back on tap and back to front on a second tap', (tester) async {
    await tester.pumpWidget(harness(const Text('FRONT'), const Text('BACK')));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FlippableIdCard));
    await tester.pumpAndSettle();
    expect(find.text('BACK'), findsOneWidget);
    expect(find.text('FRONT'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(FlippableIdCard));
    await tester.pumpAndSettle();
    expect(find.text('FRONT'), findsOneWidget);
    expect(find.text('BACK'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not throw mid-animation for content sized only by its own children', (tester) async {
    // A stand-in for the real ID card back — fixed-size content, no
    // Expanded/Spacer — pumped one frame at a time through the flip so any
    // unbounded-constraint error during the transform would surface here.
    await tester.pumpWidget(harness(
      const SizedBox(height: 200, width: 300, child: Center(child: Text('FRONT'))),
      const SizedBox(height: 200, width: 300, child: Center(child: Text('BACK'))),
    ));
    await tester.tap(find.byType(FlippableIdCard));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
    }
  });
}
