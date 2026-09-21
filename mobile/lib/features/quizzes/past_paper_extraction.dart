import 'dart:convert';
import '../../data/models/quiz_models.dart';

/// Pure parsing logic for import_past_paper_screen.dart's Gemini
/// extraction step — split out so the JSON-shape handling (including
/// Gemini's habit of wrapping JSON in markdown fences despite being told
/// not to) is unit-testable without a widget/PDF/network harness.
class PastPaperExtraction {
  PastPaperExtraction._();

  static const systemPrompt = '''
You are extracting quiz questions from a real university exam past paper's raw text. Read the text and identify individual exam questions.

Respond with ONLY a JSON array (no markdown fences, no commentary) where each item has this exact shape:
{"questionType": "multiple_choice" | "open_ended", "questionText": "...", "options": ["...", "..."] (only for multiple_choice), "correctOption": 0 (index into options, only for multiple_choice, your best guess if not stated), "modelAnswer": "..." (a concise model answer, required for open_ended, optional explanation for multiple_choice)}

If the paper has no clearly extractable questions, respond with an empty array [].''';

  /// Keeps the request reasonably sized — a long paper still yields enough
  /// material for a useful practice set even if extraction stops partway.
  static const maxExtractedChars = 15000;

  static String truncate(String text) => text.length > maxExtractedChars ? text.substring(0, maxExtractedChars) : text;

  /// Returns an empty list on any malformed/unparseable response — the
  /// caller treats that the same as "nothing was extracted" and offers a
  /// retry or manual-entry path, never a crash.
  static List<QuizQuestionDraft> parseQuestions(String geminiReply) {
    final cleaned = _stripMarkdownFences(geminiReply.trim());

    try {
      final decoded = jsonDecode(cleaned) as List;
      return decoded.map(_draftFromJson).toList();
    } catch (_) {
      return [];
    }
  }

  static String _stripMarkdownFences(String text) {
    if (!text.startsWith('```')) return text;
    var cleaned = text.replaceFirst(RegExp(r'^```(json)?'), '').trim();
    if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3).trim();
    return cleaned;
  }

  static QuizQuestionDraft _draftFromJson(dynamic item) {
    final map = item as Map<String, dynamic>;
    final type = map['questionType'] == 'multiple_choice' ? QuestionType.multipleChoice : QuestionType.openEnded;
    return QuizQuestionDraft(
      questionType: type,
      questionText: (map['questionText'] as String?)?.trim() ?? '',
      options: type == QuestionType.multipleChoice
          ? ((map['options'] as List?)?.map((e) => e.toString()).toList() ?? ['', ''])
          : null,
      correctOption: type == QuestionType.multipleChoice ? ((map['correctOption'] as num?)?.toInt() ?? 0) : null,
      modelAnswer: map['modelAnswer'] as String?,
    );
  }
}
