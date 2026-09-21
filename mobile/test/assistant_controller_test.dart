import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/assistant/assistant_controller.dart';
import 'package:mobile/features/assistant/context_aggregator.dart';
import 'package:mobile/features/assistant/models/assistant_message.dart';

import 'support/assistant_fakes.dart';

ProviderContainer _container(FakeGemini gemini, {Future<AssistantContext> Function()? context}) {
  final container = ProviderContainer(overrides: [
    geminiAssistantServiceProvider.overrideWithValue(gemini),
    assistantContextProvider.overrideWith((ref) => (context ?? () async => sampleContext())()),
  ]);
  addTearDown(container.dispose);
  return container;
}

List<String> _texts(ProviderContainer c) => c.read(assistantControllerProvider).map((m) => m.text).toList();

void main() {
  group('sendMessage', () {
    test('a reply from Gemini is shown and not marked as a fallback', () async {
      final gemini = FakeGemini(reply: 'You have Maths at 10.');
      final container = _container(gemini);

      await container.read(assistantControllerProvider.notifier).sendMessage('  What classes today?  ');

      final messages = container.read(assistantControllerProvider);
      expect(messages.map((m) => m.sender), [MessageSender.user, MessageSender.assistant]);
      expect(messages.first.text, 'What classes today?', reason: 'trimmed');
      expect(messages.last.text, 'You have Maths at 10.');
      expect(messages.last.isFallback, isFalse);
      expect(container.read(assistantSendingProvider), isFalse);
    });

    test('when Gemini gives nothing the local engine answers, marked as a fallback', () async {
      final container = _container(FakeGemini(reply: null));

      await container.read(assistantControllerProvider.notifier).sendMessage('how do I connect to wifi');

      final reply = container.read(assistantControllerProvider).last;
      expect(reply.isFallback, isTrue);
      expect(reply.text, contains('eduroam'));
    });

    test('the first question has no history', () async {
      final gemini = FakeGemini(reply: 'ok');
      final container = _container(gemini);

      await container.read(assistantControllerProvider.notifier).sendMessage('first');

      expect(gemini.histories.single, isEmpty);
    });

    test('a follow-up is sent with everything said before it, but not itself', () async {
      final gemini = FakeGemini(reply: 'answer');
      final container = _container(gemini);
      final controller = container.read(assistantControllerProvider.notifier);

      await controller.sendMessage('What classes today?');
      await controller.sendMessage('And tomorrow?');

      expect(gemini.queries, ['What classes today?', 'And tomorrow?']);
      expect(gemini.histories[1].map((m) => m.text), ['What classes today?', 'answer']);
      expect(gemini.histories[1].map((m) => m.text), isNot(contains('And tomorrow?')));
    });

    test('blank input is ignored', () async {
      final gemini = FakeGemini(reply: 'x');
      final container = _container(gemini);

      await container.read(assistantControllerProvider.notifier).sendMessage('   ');

      expect(gemini.queries, isEmpty);
      expect(container.read(assistantControllerProvider), isEmpty);
    });

    test('a second message while one is loading is ignored', () async {
      final gemini = FakeGemini(reply: 'ok')..gate = Completer<void>();
      final container = _container(gemini);
      final controller = container.read(assistantControllerProvider.notifier);

      final first = controller.sendMessage('one');
      await Future<void>.delayed(Duration.zero);
      await controller.sendMessage('two');
      expect(container.read(assistantSendingProvider), isTrue);

      gemini.gate!.complete();
      await first;

      expect(gemini.queries, ['one']);
      expect(_texts(container), ['one', 'ok']);
    });

    test('if the context cannot be built the student gets an apology and can try again', () async {
      final gemini = FakeGemini(reply: 'fine');
      var fail = true;
      final container = _container(gemini, context: () async {
        if (fail) throw Exception('boom');
        return sampleContext();
      });
      final controller = container.read(assistantControllerProvider.notifier);

      await controller.sendMessage('hello');
      expect(container.read(assistantControllerProvider).last.text, contains("couldn't load your campus data"));
      expect(container.read(assistantSendingProvider), isFalse, reason: 'the input is usable again');
      expect(gemini.queries, isEmpty);

      fail = false;
      container.invalidate(assistantContextProvider);
      await controller.sendMessage('hello again');
      expect(container.read(assistantControllerProvider).last.text, 'fine');
    });
  });

  group('clear', () {
    test('starts a new conversation: messages are gone and history is not carried over', () async {
      final gemini = FakeGemini(reply: 'answer');
      final container = _container(gemini);
      final controller = container.read(assistantControllerProvider.notifier);

      await controller.sendMessage('old question');
      controller.clear();
      expect(container.read(assistantControllerProvider), isEmpty);

      await controller.sendMessage('new question');
      expect(gemini.histories.last, isEmpty, reason: 'nothing from before the clear');
    });

    test('is ignored while a reply is loading, so a late answer cannot land in an empty chat', () async {
      final gemini = FakeGemini(reply: 'ok')..gate = Completer<void>();
      final container = _container(gemini);
      final controller = container.read(assistantControllerProvider.notifier);

      final pending = controller.sendMessage('question');
      await Future<void>.delayed(Duration.zero);
      controller.clear();
      expect(container.read(assistantControllerProvider), isNotEmpty);

      gemini.gate!.complete();
      await pending;
      expect(_texts(container), ['question', 'ok']);
    });
  });
}
