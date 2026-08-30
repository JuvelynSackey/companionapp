import 'package:dio/dio.dart';

/// Model id matches app/src/main/java/com/example/data/ai/CampusAssistantService.kt
/// verbatim, to stay faithful to the ported source rather than guess at a
/// different one.
const String _geminiModel = 'gemini-3.5-flash';

/// Never hardcode a real key. Pass with:
///   flutter run --dart-define=GEMINI_API_KEY=...
const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

/// Raw REST call (not the SDK), mirroring the Kotlin source. Returns null on
/// any failure (missing/blank key, network error, empty response) so the
/// caller can fall back to the local rule engine — a null result is an
/// expected, non-exceptional outcome here, not an error to propagate.
class GeminiAssistantService {
  GeminiAssistantService() : _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 30), receiveTimeout: const Duration(seconds: 30)));

  final Dio _dio;

  Future<String?> ask({required String systemPrompt, required String query}) async {
    if (geminiApiKey.isEmpty) return null;

    try {
      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent',
        queryParameters: {'key': geminiApiKey},
        data: {
          'systemInstruction': {
            'parts': [
              {'text': systemPrompt},
            ],
          },
          'contents': [
            {
              'parts': [
                {'text': query},
              ],
            },
          ],
        },
      );

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
