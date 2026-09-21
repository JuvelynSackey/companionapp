import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/assistant/assistant_controller.dart';
import 'package:mobile/features/assistant/assistant_screen.dart';
import 'package:mobile/features/assistant/context_aggregator.dart';

import 'support/assistant_fakes.dart';

Widget _app(FakeGemini gemini) => ProviderScope(
      overrides: [
        geminiAssistantServiceProvider.overrideWithValue(gemini),
        assistantContextProvider.overrideWith((ref) async => sampleContext()),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const AssistantScreen()),
    );

Finder get _newChat => find.widgetWithIcon(IconButton, Icons.add_comment_outlined);
bool _newChatEnabled(WidgetTester tester) => tester.widget<IconButton>(_newChat).onPressed != null;

Future<void> _ask(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.tap(find.byIcon(Icons.send));
  await tester.pump();
}

void main() {
  testWidgets('starts empty, with the prompt and suggestions, and New chat disabled', (tester) async {
    await tester.pumpWidget(_app(FakeGemini(reply: 'hi')));
    await tester.pumpAndSettle();

    expect(find.text('Ask your Campus Companion assistant anything.'), findsOneWidget);
    expect(find.text('Calculate my GPA'), findsOneWidget);
    expect(_newChatEnabled(tester), isFalse);
  });

  testWidgets('the badge says the local engine is in use when no Gemini key is set', (tester) async {
    await tester.pumpWidget(_app(FakeGemini(reply: 'hi')));
    await tester.pumpAndSettle();

    // (Tests run without --dart-define=GEMINI_API_KEY.)
    expect(find.text('Local engine'), findsOneWidget);
    expect(find.text('Offline Mode'), findsNothing, reason: 'being online is not the same as having no key');
  });

  testWidgets('asking shows the question and the answer, and enables New chat', (tester) async {
    await tester.pumpWidget(_app(FakeGemini(reply: 'You have Maths at **10:00**.')));
    await tester.pumpAndSettle();

    await _ask(tester, 'What classes today?');
    await tester.pumpAndSettle();

    expect(find.textContaining('What classes today?', findRichText: true), findsOneWidget);
    expect(find.textContaining('You have Maths at 10:00.', findRichText: true), findsOneWidget);
    expect(_newChatEnabled(tester), isTrue);
  });

  testWidgets('New chat clears the conversation and returns to the empty state', (tester) async {
    await tester.pumpWidget(_app(FakeGemini(reply: 'answer')));
    await tester.pumpAndSettle();
    await _ask(tester, 'a question');
    await tester.pumpAndSettle();

    await tester.tap(_newChat);
    await tester.pumpAndSettle();

    expect(find.text('Ask your Campus Companion assistant anything.'), findsOneWidget);
    expect(find.textContaining('a question', findRichText: true), findsNothing);
    expect(_newChatEnabled(tester), isFalse);
  });

  testWidgets('a question asked after New chat is sent with no history', (tester) async {
    final gemini = FakeGemini(reply: 'answer');
    await tester.pumpWidget(_app(gemini));
    await tester.pumpAndSettle();

    await _ask(tester, 'old question');
    await tester.pumpAndSettle();
    await tester.tap(_newChat);
    await tester.pumpAndSettle();
    await _ask(tester, 'new question');
    await tester.pumpAndSettle();

    expect(gemini.histories.last, isEmpty);
  });

  testWidgets('New chat is disabled while a reply is loading', (tester) async {
    final gemini = FakeGemini(reply: 'answer')..gate = Completer<void>();
    await tester.pumpWidget(_app(gemini));
    await tester.pumpAndSettle();

    await _ask(tester, 'slow question');
    await tester.pump(const Duration(milliseconds: 300));

    expect(_newChatEnabled(tester), isFalse);

    gemini.gate!.complete();
    await tester.pumpAndSettle();
    expect(_newChatEnabled(tester), isTrue);
  });

  testWidgets('a follow-up question is sent with the earlier exchange', (tester) async {
    final gemini = FakeGemini(reply: 'answer');
    await tester.pumpWidget(_app(gemini));
    await tester.pumpAndSettle();

    await _ask(tester, 'What classes today?');
    await tester.pumpAndSettle();
    await _ask(tester, 'And tomorrow?');
    await tester.pumpAndSettle();

    expect(gemini.histories.last.map((m) => m.text), ['What classes today?', 'answer']);
  });
}
