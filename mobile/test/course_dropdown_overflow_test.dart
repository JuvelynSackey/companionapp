import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The course pickers (Quizzes, Tutor) on a phone-width screen with a long
// course name: isExpanded + ellipsis must keep them inside the screen.
void main() {
  testWidgets('a long course name fits a phone-width course dropdown', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const label = 'DCIT 401 · Social, Legal, Ethical & Professional Issues in Computing';
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<int>(
            initialValue: 1,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Course', prefixIcon: Icon(Icons.menu_book_outlined)),
            items: const [DropdownMenuItem(value: 1, child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis))],
            onChanged: (_) {},
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull, reason: 'no RenderFlex overflow');
  });
}
