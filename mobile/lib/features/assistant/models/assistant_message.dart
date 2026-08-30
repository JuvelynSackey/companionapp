enum MessageSender { user, assistant }

class AssistantMessage {
  AssistantMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.isFallback = false,
  });

  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;

  /// True when this reply came from the local rule engine, not Gemini
  /// (no/invalid API key, or the request failed) — lets the UI show a
  /// small "offline" indicator if desired.
  final bool isFallback;
}
