import 'package:dio/dio.dart';
import 'models/assistant_message.dart';

/// Gemini model id used by this service.
const String _geminiModel = 'gemini-3.5-flash';

/// Never hardcode a real key. Pass with:
///   flutter run --dart-define=GEMINI_API_KEY=...
const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

/// Raw REST call (not the SDK). Returns null on
/// any failure (missing/blank key, network error, empty response) so the
/// caller can fall back to the local rule engine — a null result is an
/// expected, non-exceptional outcome here, not an error to propagate.
class GeminiAssistantService {
  /// [dio], [apiKey] and [retryDelay] are only overridden in tests; the app
  /// uses the defaults (the --dart-define key and a client that waits up to
  /// 60s, since replies were measured at 20-27s on 4 Nov 2026).
  GeminiAssistantService({Dio? dio, String? apiKey, this._retryDelay = const Duration(seconds: 2)})
      : _dio = dio ??
            Dio(BaseOptions(connectTimeout: const Duration(seconds: 30), receiveTimeout: const Duration(seconds: 60))),
        _apiKey = apiKey ?? geminiApiKey;

  final Dio _dio;
  final String _apiKey;

  /// Pause before the single retry of a "busy" reply (see [_retryStatuses]).
  final Duration _retryDelay;

  /// Statuses Gemini returns when it is briefly overloaded or rate-limited
  /// (503 "model is experiencing high demand" was seen in testing). These
  /// are retried once; anything else goes straight to the local fallback.
  static const _retryStatuses = {429, 503};

  /// How many earlier messages are sent along so follow-ups ("and tomorrow?")
  /// make sense, without the request growing forever.
  static const maxHistoryMessages = 10;

  /// The `contents` for a request: recent [history] followed by [query] as the
  /// newest user turn. Gemini wants turns that alternate user / model and start
  /// with a user turn, so consecutive turns from the same side are merged and
  /// any leading model turn is dropped. Blank messages are skipped.
  static List<Map<String, dynamic>> buildContents({
    required List<AssistantMessage> history,
    required String query,
  }) {
    final recent = history.length > maxHistoryMessages ? history.sublist(history.length - maxHistoryMessages) : history;

    final turns = <({String role, String text})>[];
    void add(String role, String text) {
      final trimmed = text.trim();
      if (trimmed.isEmpty) return;
      if (turns.isNotEmpty && turns.last.role == role) {
        turns[turns.length - 1] = (role: role, text: '${turns.last.text}\n\n$trimmed');
      } else {
        turns.add((role: role, text: trimmed));
      }
    }

    for (final message in recent) {
      add(message.sender == MessageSender.user ? 'user' : 'model', message.text);
    }
    while (turns.isNotEmpty && turns.first.role == 'model') {
      turns.removeAt(0);
    }
    add('user', query);

    return [
      for (final turn in turns)
        {
          'role': turn.role,
          'parts': [
            {'text': turn.text},
          ],
        },
    ];
  }

  Future<String?> ask({
    required String systemPrompt,
    required String query,
    List<AssistantMessage> history = const [],
  }) async {
    if (_apiKey.isEmpty) return null;

    Future<Response<dynamic>> send() => _dio.post(
          'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent',
          queryParameters: {'key': _apiKey},
          data: {
            'systemInstruction': {
              'parts': [
                {'text': systemPrompt},
              ],
            },
            'contents': buildContents(history: history, query: query),
          },
        );

    try {
      Response<dynamic> response;
      try {
        response = await send();
      } on DioException catch (e) {
        if (!_retryStatuses.contains(e.response?.statusCode)) rethrow;
        await Future<void>.delayed(_retryDelay);
        response = await send();
      }

      final candidates = response.data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return null;
      final parts = candidates.first['content']?['parts'] as List?;
      if (parts == null || parts.isEmpty) return null;
      final text = parts.first['text'] as String?;
      return (text != null && text.trim().isNotEmpty) ? text.trim() : null;
    } catch (_) {
      return null;
    }
  }
}
