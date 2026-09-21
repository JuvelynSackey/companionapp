import 'package:flutter/material.dart';
import '../../../core/theme/campus_companion_theme.dart';
import '../models/assistant_message.dart';

/// Shared chat UI (message list, typing indicator, quick-suggestion chips,
/// input bar) — extracted from the original AssistantScreen so the
/// course-focused AI Tutor screen can reuse it instead of duplicating
/// ~150 lines of chat presentation code. Deliberately Riverpod-agnostic
/// (plain StatefulWidget): the caller owns its own controller/provider and
/// just passes the current messages/sending state down.
class ChatView extends StatefulWidget {
  const ChatView({
    super.key,
    required this.messages,
    required this.isSending,
    required this.quickSuggestions,
    required this.onSend,
    required this.emptyStateText,
    this.inputHint = 'Type a message...',
  });

  final List<AssistantMessage> messages;
  final bool isSending;
  final List<String> quickSuggestions;
  final void Function(String) onSend;
  final String emptyStateText;
  final String inputHint;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant ChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length) {
      _scrollToBottom();
    }
  }

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
    widget.onSend(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final campus = Theme.of(context).campusTheme;
    final messages = widget.messages;

    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? _EmptyState(text: widget.emptyStateText, suggestions: widget.quickSuggestions, onSuggestionTap: _send)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length + (widget.isSending ? 1 : 0),
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
                for (final suggestion in widget.quickSuggestions)
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
                    decoration: campus.inputDecoration(hint: widget.inputHint),
                    onSubmitted: _send,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: campus.accentGlow),
                  icon: const Icon(Icons.send),
                  onPressed: widget.isSending ? null : () => _send(_inputController.text),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text, required this.suggestions, required this.onSuggestionTap});
  final String text;
  final List<String> suggestions;
  final void Function(String) onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    // Centers when the content fits, but scrolls instead of overflowing on
    // short screens — the icon + text + suggestion chips can exceed a small
    // phone's available height once the app bar and input bar are accounted for.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 48, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(text, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final suggestion in suggestions)
                          ActionChip(label: Text(suggestion), onPressed: () => onSuggestionTap(suggestion)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
              border: Border.all(
                color: isUser ? campus.accentGlow.withValues(alpha: 0.6) : campus.subtleBorder,
                width: isUser ? 1.5 : 1,
              ),
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
