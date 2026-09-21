import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'assistant_controller.dart';
import 'gemini_assistant_service.dart';
import 'widgets/chat_view.dart';

const _quickSuggestions = [
  "What's my next class?",
  'When is my next exam?',
  'Where are vacant study desks?',
  'Calculate my GPA',
];

class AssistantScreen extends ConsumerWidget {
  const AssistantScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(assistantControllerProvider);
    final isSending = ref.watch(assistantSendingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        actions: const [Padding(padding: EdgeInsets.only(right: 16), child: Center(child: _StatusBadge()))],
      ),
      body: ChatView(
        messages: messages,
        isSending: isSending,
        quickSuggestions: _quickSuggestions,
        emptyStateText: 'Ask your Campus Companion assistant anything.',
        inputHint: 'Ask about classes, exams, GPA...',
        onSend: (text) => ref.read(assistantControllerProvider.notifier).sendMessage(text),
      ),
    );
  }
}

/// Reflects whether a Gemini key is *configured* (--dart-define=GEMINI_API_KEY),
/// not a live health check — a configured key can still fail per-request
/// (network, quota, etc.), which is why each reply also carries its own
/// isFallback flag (see ChatView's _ChatBubble) as the real per-message signal.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge();

  @override
  Widget build(BuildContext context) {
    final online = geminiApiKey.isNotEmpty;
    final color = online ? Colors.green.shade700 : Colors.orange.shade800;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text(
            online ? 'Online (Gemini)' : 'Offline Mode',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
