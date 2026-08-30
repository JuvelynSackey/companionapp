import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/campus_companion_theme.dart';
import 'assistant_controller.dart';
import 'gemini_assistant_service.dart';
import 'models/assistant_message.dart';

const _quickSuggestions = [
  "What's my next class?",
  'When is my next exam?',
  'Where are vacant study desks?',
  'Calculate my GPA',
];

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    _inputController.clear();
    ref.read(assistantControllerProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(assistantControllerProvider);
    final isSending = ref.watch(assistantSendingProvider);
    final campus = Theme.of(context).campusTheme;

    ref.listen(assistantControllerProvider, (_, _) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        actions: const [Padding(padding: EdgeInsets.only(right: 16), child: Center(child: _StatusBadge()))],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _EmptyState(onSuggestionTap: _send)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length + (isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length) return const _TypingIndicator();
                      return _ChatBubble(message: messages[index]);
                    },
                  ),
          ),
          if (messages.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final suggestion in _quickSuggestions)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: ActionChip(
                        label: Text(suggestion),
                        onPressed: () => _send(suggestion),
                        backgroundColor: campus.cardBackground,
                        side: BorderSide(color: campus.subtleBorder),
                        labelStyle: TextStyle(color: campus.accentGlow, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(campus.innerRadius)),
                      ),
                    ),
                ],
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: campus.inputDecoration(hint: 'Ask about classes, exams, GPA...'),
                      onSubmitted: _send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: campus.accentGlow),
                    icon: const Icon(Icons.send),
                    onPressed: isSending ? null : () => _send(_inputController.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reflects whether a Gemini key is *configured* (--dart-define=GEMINI_API_KEY),
/// not a live health check — a configured key can still fail per-request
/// (network, quota, etc.), which is why each reply also carries its own
/// isFallback flag (see the tag on _ChatBubble) as the real per-message signal.
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onSuggestionTap});
  final void Function(String) onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            const Text('Ask your Campus Companion assistant anything.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final suggestion in _quickSuggestions)
                  ActionChip(label: Text(suggestion), onPressed: () => onSuggestionTap(suggestion)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});
  final AssistantMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    final campus = Theme.of(context).campusTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            decoration: BoxDecoration(
              color: campus.cardBackground,
              borderRadius: BorderRadius.circular(campus.cardRadius),
              border: Border.all(color: isUser ? campus.accentGlow.withValues(alpha: 0.6) : campus.subtleBorder, width: isUser ? 1.5 : 1),
            ),
            child: Text(message.text, style: TextStyle(color: colorScheme.onSurface)),
          ),
          if (message.isFallback)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
              child: Text(
                'via Local Engine',
                style: TextStyle(fontSize: 10, color: Colors.orange.shade800, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final campus = Theme.of(context).campusTheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: campus.cardDecoration(),
        child: SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: campus.accentGlow)),
      ),
    );
  }
}
