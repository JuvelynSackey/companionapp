import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'context_aggregator.dart';
import 'gemini_assistant_service.dart';
import 'local_assistant_engine.dart';
import 'models/assistant_message.dart';

final geminiAssistantServiceProvider = Provider<GeminiAssistantService>((ref) => GeminiAssistantService());

/// Separate from the message list so the UI can show a typing indicator
/// without it being just a transient field the widget tree can't observe.
final assistantSendingProvider = StateProvider<bool>((ref) => false);

class AssistantController extends Notifier<List<AssistantMessage>> {
  int _nextId = 0;
  String _newId() => 'msg_${_nextId++}';

  @override
  List<AssistantMessage> build() => [];

  Future<void> sendMessage(String query) async {
    if (query.trim().isEmpty || ref.read(assistantSendingProvider)) return;
    ref.read(assistantSendingProvider.notifier).state = true;

    state = [
      ...state,
      AssistantMessage(id: _newId(), text: query.trim(), sender: MessageSender.user, timestamp: DateTime.now()),
    ];

    try {
      final context = await ref.read(assistantContextProvider.future);
      final geminiReply = await ref.read(geminiAssistantServiceProvider).ask(
            systemPrompt: context.toSystemPrompt(),
            query: query.trim(),
          );

      final replyText = geminiReply ?? LocalAssistantEngine.respond(query, context);
      state = [
        ...state,
        AssistantMessage(
          id: _newId(),
          text: replyText,
          sender: MessageSender.assistant,
          timestamp: DateTime.now(),
          isFallback: geminiReply == null,
        ),
      ];
    } catch (_) {
      state = [
        ...state,
        AssistantMessage(
          id: _newId(),
          text: "Sorry, I couldn't load your campus data just now. Please try again.",
          sender: MessageSender.assistant,
          timestamp: DateTime.now(),
          isFallback: true,
        ),
      ];
    } finally {
      ref.read(assistantSendingProvider.notifier).state = false;
    }
  }
}

final assistantControllerProvider = NotifierProvider<AssistantController, List<AssistantMessage>>(
  AssistantController.new,
);
