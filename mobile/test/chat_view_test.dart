import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/assistant/models/assistant_message.dart';
import 'package:mobile/features/assistant/widgets/chat_view.dart';

AssistantMessage _msg(int i, MessageSender sender, String text, {bool fallback = false}) => AssistantMessage(
      id: 'm$i',
      text: text,
      sender: sender,
      timestamp: DateTime(2030),
      isFallback: fallback,
    );

const _suggestions = ["What's my next class?", 'Calculate my GPA'];

/// Rebuildable ChatView, so a test can flip isSending / add messages the way
/// the real controller does.
class _Harness extends StatefulWidget {
  const _Harness({super.key, required this.onSend, this.messages = const [], this.isSending = false});
  final void Function(String) onSend;
  final List<AssistantMessage> messages;
  final bool isSending;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late List<AssistantMessage> messages = widget.messages;
  late bool isSending = widget.isSending;

  void update({List<AssistantMessage>? messages, bool? isSending}) => setState(() {
        this.messages = messages ?? this.messages;
        this.isSending = isSending ?? this.isSending;
      });

  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: ChatView(
            messages: messages,
            isSending: isSending,
            quickSuggestions: _suggestions,
            emptyStateText: 'Ask me anything.',
            onSend: widget.onSend,
          ),
        ),
      );
}

Finder get _input => find.byType(TextField);

IconButton _send(WidgetTester tester) => tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send));

void main() {
  testWidgets('empty state shows the prompt and suggestions; tapping one sends it', (tester) async {
    final sent = <String>[];
    await tester.pumpWidget(_Harness(onSend: sent.add));

    expect(find.text('Ask me anything.'), findsOneWidget);
    await tester.tap(find.text("What's my next class?"));
    await tester.pump();

    expect(sent, ["What's my next class?"]);
  });

  testWidgets('typing and pressing send calls onSend with the text and clears the box', (tester) async {
    final sent = <String>[];
    await tester.pumpWidget(_Harness(onSend: sent.add));

    await tester.enterText(_input, 'When is my exam?');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    expect(sent, ['When is my exam?']);
    expect(tester.widget<TextField>(_input).controller!.text, isEmpty);
  });

  testWidgets('blank input sends nothing', (tester) async {
    final sent = <String>[];
    await tester.pumpWidget(_Harness(onSend: sent.add));

    await tester.enterText(_input, '   ');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    expect(sent, isEmpty);
  });

  group('while a reply is loading', () {
    final messages = [_msg(0, MessageSender.user, 'first question')];

    testWidgets('pressing Enter keeps what was typed and sends nothing (it used to clear the box and drop it)', (tester) async {
      final sent = <String>[];
      await tester.pumpWidget(_Harness(onSend: sent.add, messages: messages, isSending: true));

      await tester.enterText(_input, 'my next question');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(milliseconds: 300));

      expect(sent, isEmpty);
      expect(tester.widget<TextField>(_input).controller!.text, 'my next question');
    });

    testWidgets('the send button is disabled', (tester) async {
      await tester.pumpWidget(_Harness(onSend: (_) {}, messages: messages, isSending: true));
      await tester.pump(const Duration(milliseconds: 300));

      expect(_send(tester).onPressed, isNull);
    });

    testWidgets('the suggestion chips are disabled', (tester) async {
      final sent = <String>[];
      await tester.pumpWidget(_Harness(onSend: sent.add, messages: messages, isSending: true));
      await tester.pump(const Duration(milliseconds: 300));

      final chip = tester.widget<ActionChip>(find.widgetWithText(ActionChip, "What's my next class?"));
      expect(chip.onPressed, isNull);
      await tester.tap(find.text("What's my next class?"), warnIfMissed: false);
      expect(sent, isEmpty);
    });

    testWidgets('a typing indicator is shown, and goes away when the reply arrives', (tester) async {
      final harness = GlobalKey<_HarnessState>();
      await tester.pumpWidget(_Harness(key: harness, onSend: (_) {}, messages: messages, isSending: true));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      harness.currentState!.update(
        isSending: false,
        messages: [...messages, _msg(1, MessageSender.assistant, 'the answer')],
      );
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('the answer', findRichText: true), findsOneWidget);
    });

    testWidgets('once the reply is in, the same text can be sent again', (tester) async {
      final harness = GlobalKey<_HarnessState>();
      final sent = <String>[];
      await tester.pumpWidget(_Harness(key: harness, onSend: sent.add, messages: messages, isSending: true));
      await tester.enterText(_input, 'kept text');
      await tester.pump(const Duration(milliseconds: 300));

      harness.currentState!.update(isSending: false);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      expect(sent, ['kept text']);
    });
  });

  testWidgets('the typing indicator is scrolled into view in a long conversation', (tester) async {
    final harness = GlobalKey<_HarnessState>();
    final long = [
      for (var i = 0; i < 40; i++) _msg(i, i.isEven ? MessageSender.user : MessageSender.assistant, 'message number $i'),
    ];
    await tester.pumpWidget(_Harness(key: harness, onSend: (_) {}, messages: long));
    await tester.pumpAndSettle();

    harness.currentState!.update(isSending: true);
    // Step through the scroll animation frame by frame, as a device does (one
    // big pump counts as a single animation tick).
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    final indicator = tester.getRect(find.byType(CircularProgressIndicator));
    expect(indicator.bottom, lessThanOrEqualTo(screen.height), reason: 'not hidden below the visible list');
    expect(indicator.top, greaterThanOrEqualTo(0));
  });

  group('message bubbles', () {
    testWidgets('markdown is formatted, not shown as raw asterisks', (tester) async {
      await tester.pumpWidget(_Harness(
        onSend: (_) {},
        messages: [_msg(0, MessageSender.assistant, '🚌 **Campus Shuttle**: runs every *10* minutes')],
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Campus Shuttle', findRichText: true), findsOneWidget);
      expect(find.textContaining('**', findRichText: true), findsNothing);
      expect(find.textContaining('*10*', findRichText: true), findsNothing);
    });

    testWidgets('the text can be selected and copied', (tester) async {
      await tester.pumpWidget(_Harness(
        onSend: (_) {},
        messages: [_msg(0, MessageSender.assistant, 'You have Maths at 10:00')],
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SelectableText), findsOneWidget);
    });

    testWidgets('a local-engine reply is badged, a Gemini reply is not', (tester) async {
      await tester.pumpWidget(_Harness(
        onSend: (_) {},
        messages: [
          _msg(0, MessageSender.assistant, 'from gemini'),
          _msg(1, MessageSender.assistant, 'from the local engine', fallback: true),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('via Local Engine'), findsOneWidget);
    });

    testWidgets('long messages wrap instead of overflowing', (tester) async {
      await tester.pumpWidget(_Harness(
        onSend: (_) {},
        messages: [_msg(0, MessageSender.user, 'word ' * 200)],
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
