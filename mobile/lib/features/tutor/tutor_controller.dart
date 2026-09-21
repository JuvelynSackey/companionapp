import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../assistant/assistant_controller.dart' show geminiAssistantServiceProvider;
import '../assistant/models/assistant_message.dart';
import 'local_tutor_engine.dart';
import 'tutor_context.dart';

/// Same geminiReply-or-fallback pattern as AssistantController, scoped to
/// one course. A fresh controller instance per course (family) so switching
/// the course picker starts a new conversation rather than mixing courses
/// into one history.
final tutorSendingProvider = StateProvider.family<bool, int>((ref, courseId) => false);

class TutorController extends FamilyNotifier<List<AssistantMessage>, int> {
  int _nextId = 0;
  String _newId() => 'tutor_msg_${_nextId++}';

  @override
  List<AssistantMessage> build(int courseId) => [];

  Future<void> sendMessage(String query) async {
    final courseId = arg;
    if (query.trim().isEmpty || ref.read(tutorSendingProvider(courseId))) return;
    ref.read(tutorSendingProvider(courseId).notifier).state = true;

    final history = state; // what was said before this question, for follow-ups
    state = [
      ...state,
      AssistantMessage(id: _newId(), text: query.trim(), sender: MessageSender.user, timestamp: DateTime.now()),
    ];

    try {
      final context = await ref.read(tutorContextProvider(courseId).future);
      final geminiReply = await ref.read(geminiAssistantServiceProvider).ask(
            systemPrompt: context.toSystemPrompt(),
            query: query.trim(),
            history: history,
          );

      final replyText = geminiReply ?? LocalTutorEngine.respond(query, context);
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
          text: "Sorry, I couldn't load this course's data just now. Please try again.",
          sender: MessageSender.assistant,
          timestamp: DateTime.now(),
          isFallback: true,
        ),
      ];
    } finally {
      ref.read(tutorSendingProvider(courseId).notifier).state = false;
    }
  }
}

final tutorControllerProvider =
    NotifierProvider.family<TutorController, List<AssistantMessage>, int>(TutorController.new);
