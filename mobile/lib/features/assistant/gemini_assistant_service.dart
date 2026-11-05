import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'models/assistant_message.dart';

/// The Gemini model for every request: Flash-Lite, the fastest current model
/// (answers took about 2-13 s against 15 s for Flash on 5 Nov 2026, and it
/// read an attached 1.2 MB PDF correctly).
const String geminiModel = 'gemini-3.5-flash-lite';

/// When [geminiModel] answers "busy", the single retry goes to this other
/// model instead of queueing on the overloaded one again.
const String geminiRetryModel = 'gemini-3.1-flash-lite';

/// A file sent along with a question, e.g. a course's lecture slides as a PDF.
class GeminiAttachment {
  const GeminiAttachment({required this.name, required this.mimeType, required this.bytes});
  final String name;
  final String mimeType;
  final Uint8List bytes;
}

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
    GeminiAttachment? attachment,
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
      for (var i = 0; i < turns.length; i++)
        {
          'role': turns[i].role,
          'parts': [
            // The attachment rides on the newest question, so the model reads
            // it fresh each time instead of relying on an earlier turn.
            if (attachment != null && i == turns.length - 1)
              {
                'inline_data': {'mime_type': attachment.mimeType, 'data': base64Encode(attachment.bytes)},
              },
            {'text': turns[i].text},
          ],
        },
    ];
  }

  Future<String?> ask({
    required String systemPrompt,
    required String query,
    List<AssistantMessage> history = const [],
    GeminiAttachment? attachment,
  }) async {
    if (_apiKey.isEmpty) return null;

    Future<Response<dynamic>> send(String model) => _dio.post(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
          queryParameters: {'key': _apiKey},
          data: {
            'systemInstruction': {
              'parts': [
                {'text': systemPrompt},
              ],
            },
            'contents': buildContents(history: history, query: query, attachment: attachment),
          },
        );

    try {
      Response<dynamic> response;
      try {
        response = await send(geminiModel);
      } on DioException catch (e) {
        if (!_retryStatuses.contains(e.response?.statusCode)) rethrow;
        await Future<void>.delayed(_retryDelay);
        response = await send(geminiRetryModel);
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
